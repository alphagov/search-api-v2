module DiscoveryEngine::Sync
  class Delete < Operation
    def initialize(content_id, payload_version: nil, client: nil)
      super(:delete, content_id, payload_version:, client:)
    end

    def call
      sync do
        client.delete_document(name: document_name)
      rescue Google::Cloud::NotFoundError => e
        increment_counter("already_not_present")
        log(
          Logger::Severity::INFO,
          "Did not delete document as it doesn't exist remotely (#{e.message}).",
        )
      end
    end
  end
end
