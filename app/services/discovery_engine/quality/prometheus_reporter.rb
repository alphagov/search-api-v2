module DiscoveryEngine::Quality
  class PrometheusReporter
    def send(quality_metrics, month_label, table_id)
      metric_collector.record_evaluations(
        quality_metrics,
        month_label,
        table_id,
      )

      push_client.add(registry)
    end

  private

    def metric_collector
      @metric_collector ||= Metrics::Evaluation.new(registry)
    end

    def registry
      @registry ||= Prometheus::Client.registry
    end

    def push_client
      @push_client ||=
        Prometheus::Client::Push.new(
          job: "evaluation_report_quality_metrics",
          gateway: ENV.fetch("PROMETHEUS_PUSHGATEWAY_URL"),
        )
    end
  end
end
