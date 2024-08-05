module Metrics
  class QualityMonitoring
    def initialize(registry)
      @quality_monitoring_score = registry.gauge(
        :search_api_v2_quality_monitoring_score,
        docstring: "Quality monitoring scores for Search API v2 (between 0 and 1)",
        labels: %i[dataset_type dataset_name],
      )
      @quality_monitoring_failures = registry.gauge(
        :search_api_v2_quality_monitoring_failures,
        docstring: "Quality monitoring failure count for Search API v2",
        labels: %i[dataset_type dataset_name],
      )
      @quality_monitoring_total = registry.gauge(
        :search_api_v2_quality_monitoring_total,
        docstring: "Quality monitoring total count for Search API v2",
        labels: %i[dataset_type dataset_name],
      )
    end

    def record_score(dataset_type, dataset_name, score)
      quality_monitoring_score.set(score, labels: {
        dataset_type: dataset_type.to_s,
        dataset_name: dataset_name.to_s,
      })
    end

    def record_failure_count(dataset_type, dataset_name, count)
      quality_monitoring_failures.set(count, labels: {
        dataset_type: dataset_type.to_s,
        dataset_name: dataset_name.to_s,
      })
    end

    def record_total_count(dataset_type, dataset_name, count)
      quality_monitoring_total.set(count, labels: {
        dataset_type: dataset_type.to_s,
        dataset_name: dataset_name.to_s,
      })
    end

  private

    attr_reader :quality_monitoring_score, :quality_monitoring_failures, :quality_monitoring_total
  end
end
