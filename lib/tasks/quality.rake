require "prometheus/client"
require "prometheus/client/push"

namespace :quality do
  desc "Create a sample query set for last month's clickstream data and import from BigQuery"
  task setup_sample_query_sets: :environment do
    month_interval = DiscoveryEngine::Quality::MonthInterval.previous_month
    DiscoveryEngine::Quality::SampleQuerySet.new("clickstream", month_interval).create_and_import
  end

  desc "Create a sample query set for clickstream data for a given month, and import from BigQuery"
  task :setup_sample_query_set, %i[year month] => :environment do |_, args|
    year = args[:year]&.to_i
    month = args[:month]&.to_i
    raise "year and month are required arguments" unless year.positive? && month.positive?
    raise "arguments must be provided in YYYY MM order" if year < month

    month_interval = DiscoveryEngine::Quality::MonthInterval.new(year, month)
    DiscoveryEngine::Quality::SampleQuerySet.new("clickstream", month_interval).create_and_import
  end

  desc "Create evaluation and push results to Prometheus"
  task report_quality_metrics: :environment do
    month_intervals = {
      last_month: DiscoveryEngine::Quality::MonthInterval.previous_month,
      month_before_last: DiscoveryEngine::Quality::MonthInterval.previous_month(2),
    }
    sample_query_sets = month_intervals.transform_values do |month_interval|
      DiscoveryEngine::Quality::SampleQuerySet.new("clickstream", month_interval).id
    end

    registry = Prometheus::Client.registry
    metric_evaluation = Metrics::Evaluation.new(registry)

    sample_query_sets.each do |month_label, id|
      e = DiscoveryEngine::Quality::Evaluation.new(id).fetch_quality_metrics

      Rails.logger.info(e)

      metric_evaluation.record_evaluations(e, month_label)

      Prometheus::Client::Push.new(
        job: "evaluation_report_quality_metrics",
        gateway: ENV.fetch("PROMETHEUS_PUSHGATEWAY_URL"),
      ).add(registry)
    end
  end
end
