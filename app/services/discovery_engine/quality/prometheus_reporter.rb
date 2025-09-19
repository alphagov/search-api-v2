module DiscoveryEngine::Quality
  class PrometheusReporter
    def send(quality_metrics, month_label, table_id)
      metric_collector.record_evaluations(
        quality_metrics,
        month_label,
        table_id,
      )

      push_client.add(metric_collector.registry)
    rescue Prometheus::Client::Push::HttpError => e
      Rails.logger.warn("Failed to push evaluations to Prometheus push gateway: '#{e.message}'")
      raise e
    end

  private

    def metric_collector
      @metric_collector ||= Metrics::Evaluation.instance
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
