module DiscoveryEngine::Autocomplete
  # Updates Discovery Engine's autocomplete denylist from Google Cloud Storage
  #
  # This allows us to remove sensitive terms from any suggestions returned by the autocomplete API,
  # based on a JSONL file stored in a Google Cloud Storage bucket. While there is support for an
  # inline source, the denylist may contain sensitive terms that we don't want to store in the
  # codebase (until we have an agreed organisational approach to private/public repo splits).
  #
  # Note that an import will not remove existing entries from the denylist, so we purge the list
  # before importing.
  #
  # See https://cloud.google.com/generative-ai-app-builder/docs/configure-autocomplete#denylist
  class UpdateDenylist
    # The name of the file in the Google Cloud Storage bucket that contains the denylist
    FILENAME = "denylist.jsonl".freeze

    # The schema of the data in the JSONL file (this is the only supported option)
    DATA_SCHEMA = "suggestion_deny_list".freeze

    def initialize(client: ::Google::Cloud::DiscoveryEngine.completion_service(version: :v1))
      @client = client
    end

    def call
      purge_operation = client.purge_suggestion_deny_list_entries(parent:)
      purge_operation.wait_until_done!
      raise purge_operation.results.message if purge_operation.error?

      Rails.logger.info("Successfully purged autocomplete denylist")

      import_operation = client.import_suggestion_deny_list_entries(
        gcs_source: {
          data_schema: DATA_SCHEMA,
          input_uris: ["gs://#{bucket_name}/#{FILENAME}"],
        },
        parent:,
      )
      import_operation.wait_until_done!
      raise import_operation.results.message if import_operation.error?

      failed = import_operation.results.failed_entries_count
      raise "Failed to import #{failed} entries to autocomplete denylist" if failed.positive?

      imported = import_operation.results.imported_entries_count
      Rails.logger.info("Successfully imported #{imported} entries to autocomplete denylist")
    end

  private

    attr_reader :client

    def bucket_name
      "#{Rails.configuration.google_cloud_project_id}_vais_artifacts"
    end

    def parent
      Rails.configuration.discovery_engine_datastore
    end
  end
end
