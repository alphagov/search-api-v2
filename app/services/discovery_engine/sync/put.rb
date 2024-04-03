module DiscoveryEngine::Sync
  class Put
    MIME_TYPE = "text/html".freeze

    include DocumentName
    include Locking
    include Logging

    def initialize(client: ::Google::Cloud::DiscoveryEngine.document_service(version: :v1))
      @client = client
    end

    def call(content_id, metadata, content: "", payload_version: nil)
      with_locked_document(content_id, payload_version:) do
        if payload_newer_than_remote?(content_id, payload_version:)
          log(
            Logger::Severity::INFO,
            "Ignored as newer version (#{latest_synced_version(content_id)}) already synced",
            content_id:, payload_version:,
          )
          Metrics::Exported.increment_counter(
            :discovery_engine_requests, type: "put", status: "ignored_outdated"
          )
          return
        end

        client.update_document(
          document: {
            id: content_id,
            name: document_name(content_id),
            json_data: metadata.merge(payload_version:).to_json,
            content: {
              mime_type: MIME_TYPE,
              # The Google client expects an IO object to extract raw byte content from
              raw_bytes: StringIO.new(content),
            },
          },
          allow_missing: true,
        )

        set_latest_synced_version(content_id, payload_version)
      end

      log(Logger::Severity::INFO, "Successfully added/updated", content_id:, payload_version:)
      Metrics::Exported.increment_counter(
        :discovery_engine_requests, type: "put", status: "success"
      )
    rescue Google::Cloud::Error => e
      log(
        Logger::Severity::ERROR,
        "Failed to add/update document due to an error (#{e.message})",
        content_id:, payload_version:,
      )
      GovukError.notify(e)
      Metrics::Exported.increment_counter(:discovery_engine_requests, type: "put", status: "error")
    end

  private

    attr_reader :client
  end
end
