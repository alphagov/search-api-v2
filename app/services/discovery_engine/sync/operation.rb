module DiscoveryEngine::Sync
  class Operation
    def initialize(type, content_id, payload_version: nil, client: nil)
      @type = type
      @content_id = content_id
      @payload_version = payload_version
      @client = client || ::Google::Cloud::DiscoveryEngine.document_service(version: :v1)
    end

  private

    attr_reader :type, :content_id, :payload_version, :client

    def sync
      lock.acquire

      if version_cache.sync_required?
        yield

        version_cache.set_as_latest_synced_version

        increment_counter("success")
        log(Logger::Severity::INFO, "Successful #{type}")
      else
        increment_counter("ignored_outdated")
        log(Logger::Severity::INFO, "Ignored as newer version already synced")
      end
    rescue Google::Cloud::Error => e
      increment_counter("error")
      log(Logger::Severity::ERROR, "Failed to #{type} document due to an error (#{e.message})")
      GovukError.notify(e)
    ensure
      lock.release
    end

    def lock
      @lock ||= Coordination::DocumentLock.new(content_id)
    end

    def version_cache
      @version_cache ||= Coordination::DocumentVersionCache.new(content_id, payload_version:)
    end

    def document_name
      "#{Rails.configuration.discovery_engine_datastore_branch}/documents/#{content_id}"
    end

    def log(level, message)
      combined_message = sprintf(
        "[%s] %s content_id:%s payload_version:%d",
        self.class.name,
        message,
        content_id,
        payload_version,
      )
      Rails.logger.add(level, combined_message)
    end

    def increment_counter(status)
      Metrics::Exported.increment_counter(:discovery_engine_requests, type:, status:)
    end
  end
end
