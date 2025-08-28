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
      bucket = storage.bucket "search-api-v2-#{PROJECT_NAME}_vais_evaluation_output" # or pass it into this method
      judgement_list_name = "#{evaluation.table_id}_#{evaluation.month}_#{evaluation.year}"
      file_name = "ts=#{evaluation.create_time}/judgement_list=#{judgement_list_name}"

      # The API returns results in pages, but the list_evaluation_results()
      # method returns an enumerable that handles paging in the background.
      query_level_results = evaluation.list_evaluation_results

      # Stream to Google Cloud Storage in NDJSON format, which BigQuery can
      # query directly. This streaming method will supposedly resume after a
      # network glitch.
      bucket.create_file file_name do |io|
        query_level_results.each do |result|
          io.write(result.to_json)
          io.write("\n")
        end
      end
    end
  end
end
