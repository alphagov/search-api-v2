module DiscoveryEngine::Quality
  class PrometheusReporter
    def send(quality_metrics, evaluation)
      Rails.logger.info("#{quality_metrics}, #{evaluation}")
      true
    end
  end
end
