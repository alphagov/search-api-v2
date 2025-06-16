module DiscoveryEngine::Sync
  class Put < Operation
    MIME_TYPE = "text/html".freeze

    def initialize(content_id, metadata = nil, content: "", payload_version: nil)
      super(:put, content_id, payload_version:)

      @metadata = metadata
      @content = content
    end

    def call
      sync do
        DiscoveryEngine::Clients.document_service.update_document(
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
      end
    end

  private

    attr_reader :metadata, :content
  end
end
