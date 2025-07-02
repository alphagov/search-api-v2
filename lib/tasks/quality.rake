require "prometheus/client"
require "prometheus/client/push"

namespace :quality do
  desc "Create a sample query set for last month's clickstream data and import from BigQuery"
  task setup_sample_query_sets: :environment do
    DiscoveryEngine::Quality::SampleQuerySet.new.create_and_import
  end

  desc "Create evaluation and push results to Prometheus"
  task report_quality_metrics: :environment do
    fields = DiscoveryEngine::Quality::SampleQuerySetFields

    sample_query_sets = {
      last_month: fields.sample_query_set_id(Time.zone.now.prev_month),
      month_before_last: fields.sample_query_set_id(Time.zone.now.prev_month(2)),
    }

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
