module DiscoveryEngine::Sync
  class Delete
    include DocumentName
    include Logging

    def initialize(client: ::Google::Cloud::DiscoveryEngine.document_service(version: :v1))
      @client = client
    end

    def call(content_id, payload_version: nil)
      client.delete_document(name: document_name(content_id))

      log(Logger::Severity::INFO, "Successfully deleted", content_id:, payload_version:)
      Metrics.increment_counter(:delete_requests, status: "success")
    rescue Google::Cloud::NotFoundError => e
      log(
        Logger::Severity::INFO,
        "Did not delete document as it doesn't exist remotely (#{e.message}).",
        content_id:, payload_version:,
      )
      Metrics.increment_counter(:delete_requests, status: "already_not_present")
    rescue Google::Cloud::Error => e
      log(
        Logger::Severity::ERROR,
        "Failed to delete document due to an error (#{e.message})",
        content_id:, payload_version:,
      )
      GovukError.notify(e)
      Metrics.increment_counter(:delete_requests, status: "error")
    end

  private

    attr_reader :client
  end
end
