module DiscoveryEngine::Sync
  class Put
    MIME_TYPE = "text/html".freeze

    include DocumentName
    include Logging

    def initialize(client: ::Google::Cloud::DiscoveryEngine.document_service(version: :v1))
      @client = client
    end

    def call(content_id, metadata, content: "", payload_version: nil)
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

      log(Logger::Severity::INFO, "Successfully added/updated", content_id:, payload_version:)
      Metrics.increment_counter(:discovery_engine_requests, type: "put", status: "success")
    rescue Google::Cloud::Error => e
      log(
        Logger::Severity::ERROR,
        "Failed to add/update document due to an error (#{e.message})",
        content_id:, payload_version:,
      )
      GovukError.notify(e)
      Metrics.increment_counter(:discovery_engine_requests, type: "put", status: "error")
    end

  private

    attr_reader :client
  end
end
