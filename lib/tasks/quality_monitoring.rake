require "prometheus/client"
require "prometheus/client/push"

namespace :quality_monitoring do
  desc "Runs the invariant dataset and validates 100% recall"
  task assert_invariants: :environment do
    registry = Prometheus::Client.registry
    metric_collector = Metrics::QualityMonitoring.new(registry)

    dir = Rails.root.join("config/quality_monitoring_datasets/invariants")
    invariant_dataset_files = Dir.glob("#{dir}/*.csv")

    invariant_dataset_files.each do |file|
      QualityMonitoring::Runner.new(
        file,
        :invariants,
        cutoff: 10,
        report_query_below_score: 1.0,
        judge_by: :recall,
        metric_collector:,
      ).run
    end

    Prometheus::Client::Push.new(
      job: "quality_monitoring_assert_invariants",
      gateway: ENV.fetch("PROMETHEUS_PUSHGATEWAY_URL"),
    ).add(registry)
  end
end
