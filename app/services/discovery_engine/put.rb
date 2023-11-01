module DiscoveryEngine
  class Put
    MIME_TYPE = "text/html".freeze

    include DocumentName

    def initialize(client: ::Google::Cloud::DiscoveryEngine.document_service(version: :v1))
      @client = client
    end

    def call(content_id, metadata, content: "", payload_version: nil)
      doc = client.update_document(
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

      Rails.logger.info(sprintf("[GCDE][PUT %s@v%s] -> %s", content_id, payload_version, doc.name))
    rescue Google::Cloud::Error => e
      Rails.logger.error(sprintf("[GCDE][PUT %s@v%s] %s", content_id, payload_version, e.message))
      GovukError.notify(e)
    end

  private

    attr_reader :client
  end
end
