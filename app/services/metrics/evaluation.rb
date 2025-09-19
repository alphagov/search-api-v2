module Metrics
  class Evaluation
    TOP_K_LEVELS = %w[1 3 5 10].freeze

    def initialize
      @doc_recall = registry.gauge(
        :search_api_v2_evaluation_monitoring_recall,
        docstring: "Vertex AI search evaluation recall",
        labels: %i[top month dataset],
      )
      @doc_precision = registry.gauge(
        :search_api_v2_evaluation_monitoring_precision,
        docstring: "Vertex AI search evaluation precision",
        labels: %i[top month dataset],
      )
      @doc_ndcg = registry.gauge(
        :search_api_v2_evaluation_monitoring_ndcg,
        docstring: "Vertex AI search evaluation ndcg",
        labels: %i[top month dataset],
      )
    end

    def record_evaluations(evaluation_result, month, dataset)
      metrics.each { |key, registry| record_evaluation(key, registry, month, dataset, evaluation_result) }
    end

    def registry
      @registry ||= Prometheus::Client.registry
    end

  private

    attr_reader :doc_recall, :doc_precision, :doc_ndcg

    def metrics
      { doc_recall:, doc_precision:, doc_ndcg: }
    end

    def record_evaluation(key, registry, month, dataset, evaluation_result)
      TOP_K_LEVELS.each do |k|
        value = evaluation_result.dig(key, :"top_#{k}")
        registry.set(value, labels: { top: k, month:, dataset: }) if value.present?
      end
    end
  end
end
