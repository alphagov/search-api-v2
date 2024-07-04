module DiscoveryEngine::Sync
  class Delete < Operation
    def call
      lock.acquire

      unless version_cache.sync_required?
        log(
          Logger::Severity::INFO,
          "Ignored as newer version already synced",
        )
        Metrics::Exported.increment_counter(
          :discovery_engine_requests, type: "delete", status: "ignored_outdated"
        )
        return
      end

      client.delete_document(name: document_name)

      version_cache.set_as_latest_synced_version

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
    ensure
      lock.release
    end
  end
end
