require "google/cloud/storage"

# TODO
# - See if this actually works.
# - Rename to StorageReporter? It writes to a bucket, not to BigQuery.
# - What parameters should be passed into the `send()` method, given that it
#   ought perhaps to be similar to the Prometheus one.
# - The judgement_list_name is known only to the caller, and can't be discovered
#   from the `evaluation`.
# - Maybe refactor the client Google::Cloud::Storage.new into app/services/storage/clients.rb
module DiscoveryEngine::Quality
  class BigqueryReporter
    PROJECT_NAME = "search-api-v2-integration".freeze

    def send(evaluation)
      storage = Google::Cloud::Storage.new(project: PROJECT_NAME)
      bucket = storage.bucket "#{PROJECT_NAME}_vais_evaluation_output"

      # If we configure the evaluation results to be fetched in batches of 1000 I don't think
      # we need to worry about pagination

      results = evaluation.list_evaluation_results
      results_ndjson = results.map { |result| result.to_json }.join("\n")
      Rails.logger.info(results_ndjson)
      bucket.create_file StringIO.new(results_ndjson), file_name(evaluation)
    end

    def file_name(evaluation)
      create_time = evaluation.create_time
      table_id = evaluation.table_id
      partition_date = evaluation.display_name.split("_").last

      "create_time=#{create_time}/judgement_list=#{table_id}/partition_date=#{partition_date}/results.json"
    end
  end
end
