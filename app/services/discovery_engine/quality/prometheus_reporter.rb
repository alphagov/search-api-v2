module DiscoveryEngine::Quality
  class PrometheusReporter
    def send(evaluation)
      Rails.logger.info("Reporting aggregate metrics to Prometheus for #{evaluation.table_id}")

      metric_collector.record_evaluations(
        evaluation.quality_metrics,
        evaluation.month_label,
        evaluation.table_id,
      )

      push_client.add(registry)
    rescue Prometheus::Client::Push::HttpError => e
      Rails.logger.warn("Failed to push evaluations to Prometheus push gateway: '#{e.message}'")
      raise e
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
