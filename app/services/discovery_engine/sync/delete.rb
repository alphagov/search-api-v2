module DiscoveryEngine::Sync
  class Delete
    include DocumentName
    include Locking
    include Logging

    def initialize(client: ::Google::Cloud::DiscoveryEngine.document_service(version: :v1))
      @client = client
    end

    def call(content_id, payload_version: nil)
      with_locked_document(content_id, payload_version:) do
        client.delete_document(name: document_name(content_id))
      end

      log(Logger::Severity::INFO, "Successfully deleted", content_id:, payload_version:)
      Metrics::Exported.increment_counter(
        :discovery_engine_requests, type: "delete", status: "success"
      )
    rescue FailedToAcquireLockError => e
      log(
        Logger::Severity::ERROR,
        "Failed to delete document as lock not acquirable",
        content_id:, payload_version:,
      )
      GovukError.notify(e)
      Metrics::Exported.increment_counter(
        :discovery_engine_requests, type: "delete", status: "lock_error"
      )
    rescue Google::Cloud::NotFoundError => e
      log(
        Logger::Severity::INFO,
        "Did not delete document as it doesn't exist remotely (#{e.message}).",
        content_id:, payload_version:,
      )
      Metrics::Exported.increment_counter(
        :discovery_engine_requests, type: "delete", status: "already_not_present"
      )
    rescue Google::Cloud::Error => e
      log(
        Logger::Severity::ERROR,
        "Failed to delete document due to an error (#{e.message})",
        content_id:, payload_version:,
      )
      GovukError.notify(e)
      Metrics::Exported.increment_counter(
        :discovery_engine_requests, type: "delete", status: "error"
      )
    end

  private

    attr_reader :client
  end
end
