module DiscoveryEngine::Sync
  class Delete < Operation
    def initialize(content_id, payload_version: nil, client: nil)
      super(content_id, payload_version:, client:)

      @content_id = content_id
      @payload_version = payload_version
    end

    def call
      with_locked_document do
        if outdated_payload_version?(content_id, payload_version:)
          log(
            Logger::Severity::INFO,
            "Ignored as newer version (#{latest_synced_version(content_id)}) already synced",
          )
          Metrics::Exported.increment_counter(
            :discovery_engine_requests, type: "delete", status: "ignored_outdated"
          )
          return
        end

        client.delete_document(name: document_name)

        set_latest_synced_version(content_id, payload_version)
      end

      log(Logger::Severity::INFO, "Successfully deleted")
      Metrics::Exported.increment_counter(
        :discovery_engine_requests, type: "delete", status: "success"
      )
    rescue Google::Cloud::NotFoundError => e
      log(
        Logger::Severity::INFO,
        "Did not delete document as it doesn't exist remotely (#{e.message}).",
      )
      Metrics::Exported.increment_counter(
        :discovery_engine_requests, type: "delete", status: "already_not_present"
      )
    rescue Google::Cloud::Error => e
      log(
        Logger::Severity::ERROR,
        "Failed to delete document due to an error (#{e.message})",
      )
      GovukError.notify(e)
      Metrics::Exported.increment_counter(
        :discovery_engine_requests, type: "delete", status: "error"
      )
    end
  end
end
