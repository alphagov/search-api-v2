module DiscoveryEngine::Sync
  class Delete < Operation
    include DocumentName
    include Locking
    include Logging

    def initialize(
      content_id = nil, payload_version: nil,
      client: ::Google::Cloud::DiscoveryEngine.document_service(version: :v1)
    )
      super()

      @content_id = content_id
      @payload_version = payload_version

      @client = client
    end

    def call
      with_locked_document(content_id, payload_version:) do
        if outdated_payload_version?(content_id, payload_version:)
          log(
            Logger::Severity::INFO,
            "Ignored as newer version (#{latest_synced_version(content_id)}) already synced",
            content_id:, payload_version:,
          )
          Metrics::Exported.increment_counter(
            :discovery_engine_requests, type: "delete", status: "ignored_outdated"
          )
          return
        end

        client.delete_document(name: document_name(content_id))

        set_latest_synced_version(content_id, payload_version)
      end

      log(Logger::Severity::INFO, "Successfully deleted", content_id:, payload_version:)
      Metrics::Exported.increment_counter(
        :discovery_engine_requests, type: "delete", status: "success"
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

    attr_reader :content_id, :payload_version, :client
  end
end
