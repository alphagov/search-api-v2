require "prometheus/client"
require "prometheus/client/push"

namespace :quality do
  desc "Create sample query sets from each of last months BigQuery tables"
  task setup_sample_query_sets: :environment do
    DiscoveryEngine::Quality::SampleQuerySets.new(:this_month).create_and_import_all
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
  # or rake quality:report_quality_metrics[clickstream,binary] to target two datasets
  desc "Create evaluations, and push metrics to Prometheus and a GCP bucket"
  task :report_quality_metrics, [:table_ids] => :environment do |_, args|
    valid_table_ids = DiscoveryEngine::Quality::SampleQuerySets::BIGQUERY_TABLE_IDS
    args = args[:table_ids]
    table_ids = args.nil? ? valid_table_ids : args.split(",")

    if (table_ids - valid_table_ids).any?
      raise "Invalid arguments, expecting one or more of #{valid_table_ids.split(',').join(' ')}"
    end

    table_ids.each do |table_id|
      Rails.logger.info("Getting ready to upload and report metrics for #{table_id} datasets")
      DiscoveryEngine::Quality::EvaluationsRunner.new(table_id).upload_and_report_metrics
    end
  end
end
