module DiscoveryEngine::Sync
  class Put < Operation
    MIME_TYPE = "text/html".freeze

    def initialize(content_id, metadata = nil, content: "", payload_version: nil, client: nil)
      super(content_id, payload_version:, client:)

      @metadata = metadata
      @content = content
    end

    def call
      lock.acquire

      unless version_cache.sync_required?
        log(
          Logger::Severity::INFO,
          "Ignored as newer version already synced",
        )
        Metrics::Exported.increment_counter(
          :discovery_engine_requests, type: "put", status: "ignored_outdated"
        )
        return
      end

      client.update_document(
        document: {
          id: content_id,
          name: document_name,
          json_data: metadata.merge(payload_version:).to_json,
          content: {
            mime_type: MIME_TYPE,
            # The Google client expects an IO object to extract raw byte content from
            raw_bytes: StringIO.new(content),
          },
        },
        allow_missing: true,
      )

      version_cache.set_as_latest_synced_version

      log(Logger::Severity::INFO, "Successfully added/updated")
      Metrics::Exported.increment_counter(
        :discovery_engine_requests, type: "put", status: "success"
      )
    rescue Google::Cloud::Error => e
      log(
        Logger::Severity::ERROR,
        "Failed to add/update document due to an error (#{e.message})",
      )
      GovukError.notify(e)
      Metrics::Exported.increment_counter(:discovery_engine_requests, type: "put", status: "error")
    ensure
      lock.release
    end

  private

    attr_reader :metadata, :content
  end
end
