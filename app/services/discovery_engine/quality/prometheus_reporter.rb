module DiscoveryEngine::Quality
  class PrometheusReporter
    def send(quality_metrics, evaluation)
      metric_collector.record_evaluations(
        quality_metrics,
        evaluation.month_label,
        evaluation.table_id,
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
