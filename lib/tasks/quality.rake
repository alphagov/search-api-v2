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

    DiscoveryEngine::Quality::SampleQuerySet.new(month:, year:, table_id:).create_and_import_queries
  end

  # Example usage rake quality:report_quality_metrics would generate and report metrics for all tables
  # or rake quality:report_quality_metrics[clickstream] to target a single dataset
  desc "Create evaluations and push results to Prometheus"
  task :report_quality_metrics, [:table_id] => :environment do |_, args|
    table_id = args[:table_id]
    registry = Prometheus::Client.registry
    metric_collector = Metrics::Evaluation.new(registry)
    evaluations = DiscoveryEngine::Quality::Evaluations.new(metric_collector)

    Rails.logger.info("Getting ready to fetch quality metrics for #{table_id || 'all'} datasets")

    evaluations.collect_all_quality_metrics(table_id.presence)

    Prometheus::Client::Push.new(
      job: "evaluation_report_quality_metrics",
      gateway: ENV.fetch("PROMETHEUS_PUSHGATEWAY_URL"),
    ).add(registry)
  rescue Prometheus::Client::Push::HttpError => e
    Rails.logger.warn("Failed to push evaluations to Prometheus push gateway: '#{e.message}'")
    raise e
  end
end
