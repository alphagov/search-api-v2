require "prometheus/client"
require "prometheus/client/push"

namespace :quality do
  desc "Create sample query sets from each of last months BigQuery tables"
  task setup_sample_query_sets: :environment do
    DiscoveryEngine::Quality::SampleQuerySets.new(:last_month).create_and_import_all
  end

  desc "Create a sample query set for a given month, year and table id"
  task :setup_sample_query_set, %i[year month table_id] => :environment do |_, args|
    year = args[:year]&.to_i
    month = args[:month]&.to_i
    table_id = args[:table_id]

    raise "year and month are required arguments" unless year.positive? && month.positive?
    raise "table id is a required argument" if table_id.blank?
    raise "arguments must be provided in YYYY MM order" if year < month

    DiscoveryEngine::Quality::SampleQuerySet.new(month:, year:, table_id:).create_and_import
  end

  # Example usage rake quality:report_quality_metrics would generate and report metrics for all tables
  # or rake quality:report_quality_metrics[clickstream] to target a single dataset
  desc "Create evaluations and push results to Prometheus"
  task :report_quality_metrics, [:table_id] => :environment do |_, args|
    table_id = args[:table_id]
    registry = Prometheus::Client.registry
    metric_collector = Metrics::PrometheusCollector.new(registry)
    evaluation = DiscoveryEngine::Quality::Evaluations.new(metric_collector)

    Rails.logger.info("Getting ready to fetch quality metrics for #{table_id || 'all'} datasets")

    evaluation.collect_all_quality_metrics(table_id.presence)

    Prometheus::Client::Push.new(
      job: "evaluation_report_quality_metrics",
      gateway: ENV.fetch("PROMETHEUS_PUSHGATEWAY_URL"),
    ).add(registry)
  rescue Prometheus::Client::Push::HttpError => e
    Rails.logger.warn("Failed to push evaluations to Prometheus push gateway: '#{e.message}'")
    raise e
  end

  # Parameters:
  #
  # - replace_sample_query_set_if_exists (default: false)
  # - dataset_id (default: automated_evaluation_input)
  # - table_id
  # - partition_date (default: first day of previous month UTC)
  # - serving_config_name (default: "default")
  #
  # 1. Attempt to create a new SampleQuerySet.
  # 2. If 403 ALREADY_EXISTS is returned:
  # 3.   If !replace_sample_query_set_if_exists: exit.
  # 4.   Otherwise delete the existing SampleQuerySet and make one more attempt.
  # 5.   If 403 ALREADY_EXISTS is returned again: exit.
  # 6. Attempt to import data into the SampleQuerySet. Wait until done.
  # 7. Attempt to create an evaluation.
  # 8. In a loop, get the evaluation until status:SUCCEEDED
  desc "Evaluate one judgement list of one date and push aggregate and query-level results to BigQuery"
  task :report_quality_metrics, [:dataset_id, :table_id, :partition_date, :serving_config_name = "default"] => :environment do |_, args|
    dataset_id = args[:dataset_id]
    table_id = args[:table_id]
    partition_date = DateTime.parse(args[:partition_date]).to_date

    id = "#{table_id}_#{partition_date}"
    display_name = "#{table_id} #{partition_date}"
    description = "Generated from BigQuery table #{table_id}, partition #{partition_date}"

    sample_query_set = DiscoveryEngine::Clients
      .sample_query_set_service
      .create_sample_query_set(
        sample_query_set: {
          display_name,
          description,
        },
        sample_query_set_id: id,
        parent: Rails.application.config.discovery_engine_default_location_name,
      )

    Rails.logger.info("Created sample query set: #{sample_query_set.name}")

    operation = DiscoveryEngine::Clients
      .sample_query_service
      .import_sample_queries(
        parent: sample_query_set.name,
        bigquery_source: {
          dataset_id:,
          table_id:,
          project_id: Rails.application.config.google_cloud_project_id,
          partition_date: { # TODO: allow this not to be used, if no partition_date is provided
            year: partition_date.year,
            month: partition_date.month,
            day: partition_date.day,
          },
        },
      )
    operation.wait_until_done!

    raise operation.error.message if operation.error?

    Rails.logger.info("Imported queries into: #{sample_query_set.name}")

    operation = DiscoveryEngine::Clients
      .evaluation_service
      .create_evaluation(
        parent: Rails.application.config.discovery_engine_default_location_name,
        evaluation: {
          evaluation_spec: {
            query_set_spec: {
              sample_query_set: sample_query_set.name,
            },
            search_request: {
              serving_config: serving_config_name,
            },
          },
        },
      )
    operation.wait_until_done!

    raise operation.error.message.to_s if operation.error?

    create_evaluation_result = operation.results

    while (evaluation = DiscoveryEngine::Clients.evaluation_service.get_evaluation(name: create_evaluation_result.name))
      # TODO: break if evaluation.state == :SUCCEEDED
      Rails.logger.info("Still waiting for evaluation to complete...")
      Kernel.sleep(10)
    end

    # TODO: send aggregate metrics to a bucket
    # TODO: send query-level metrics to a bucket, in batches of 1000.
    query_level_results = DiscoveryEngine::Clients.evaluation_service.list_evaluation_results(evaluation: create_evaluation_result.name)
    ndjsons = process_ndjson_in_batches(query_level_results)
    ndjsons .each do |item|
      # Upload to a bucket.
      # TODO: upload each batch of 1000 to a bucket, before fetching any of the
      # next batch. So that memory won't be exhausted.
    end
  end
end

# Given a Gapic::PagedEnumerable (e.g. output of list_evaluation_results) return
# an array of strings. Each string is up to 1000 lines of NDJSON, where each
# line is one evaluation result.
def process_ndjson_in_batches(paged_enumerable)
  batches = []
  batch = []
  batch_size = 1000

  paged_enumerable.each do |item|
    batch << item.to_h.to_json

    if batch.size >= batch_size
      batches << batch.join("\n")
      batch.clear
    end
  end

  # Process any remaining items in the last batch
  unless batch.empty?
    batches << batch.join("\n")
  end

  return batches
end
