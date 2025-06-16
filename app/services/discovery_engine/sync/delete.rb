module DiscoveryEngine::Sync
  class Delete < Operation
    def initialize(content_id, payload_version: nil)
      super(:delete, content_id, payload_version:)
    end

    def call
      sync do
        DiscoveryEngine::Clients.document_service.delete_document(name: document_name)
      rescue Google::Cloud::NotFoundError => e
        log(
          Logger::Severity::INFO,
          "Did not delete document as it doesn't exist remotely (#{e.message}).",
        )
      end
    end
  end
end
