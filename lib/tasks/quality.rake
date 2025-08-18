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
    Rails.logger.info("Getting ready to report detailed and aggregate metrics for #{table_id || 'all'} datasets")

    prometheus_reporter = DiscoveryEngine::Quality::PrometheusReporter.new
    biqquery_reporter = DiscoveryEngine::Quality::BigQueryReporter.new
    runner = DiscoveryEngine::Quality::EvaluationsRunner.new(table_id.presence, prometheus_reporter, biqquery_reporter)
    runner.report_all_metrics
  end
end
