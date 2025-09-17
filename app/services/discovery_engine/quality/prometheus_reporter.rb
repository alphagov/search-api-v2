module DiscoveryEngine::Quality
  class PrometheusReporter
    def send(quality_metrics, month_label, table_id)
      metric_collector.record_evaluations(
        quality_metrics,
        month_label,
        table_id,
      )
    end

  private

    def metric_collector
      @metric_collector ||= Metrics::Evaluation.new(registry)
    end

    def registry
      @registry ||= Prometheus::Client.registry
    end
  end
end
