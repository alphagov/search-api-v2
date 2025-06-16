module DiscoveryEngine::Sync
  class Operation
    MAX_RETRIES_ON_ERROR = 3
    WAIT_ON_ERROR = 3.seconds

    def initialize(type, content_id, payload_version: nil)
      @type = type
      @content_id = content_id
      @payload_version = payload_version
      @attempt = 1
    end

  private

    attr_reader :type, :content_id, :payload_version, :attempt

    def sync
      lock.acquire

      if version_cache.sync_required?
        yield

        version_cache.set_as_latest_synced_version

        log(Logger::Severity::INFO, "Successful #{type}")
      else
        log(Logger::Severity::INFO, "Ignored as newer version already synced")
      end
    rescue Google::Cloud::Error => e
      if attempt < MAX_RETRIES_ON_ERROR
        log(
          Logger::Severity::WARN,
          "Failed attempt #{attempt} to #{type} document (#{e.message}), retrying",
        )
        @attempt += 1
        Kernel.sleep(WAIT_ON_ERROR)
        retry
      end

      log(
        Logger::Severity::ERROR,
        "Failed on attempt #{attempt} to #{type} document (#{e.message}), giving up",
      )
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
      [Branch.default.name, "documents", content_id].join("/")
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
  end
end
