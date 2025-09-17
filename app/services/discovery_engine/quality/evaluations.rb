module DiscoveryEngine::Quality
  class Evaluations
    MONTH_LABELS = %i[last_month month_before_last].freeze

    def initialize(metric_collector)
      @metric_collector = metric_collector
    end

    def collect_all_quality_metrics(table_id = nil)
      MONTH_LABELS.each { |month_label| collect_quality_metrics(month_label, table_id) }
    end

  private

    attr_reader :metric_collector

    def collect_quality_metrics(month_label, table_id = nil)
      Array(sample_query_sets(month_label, table_id)).each do |set|
        quality_metrics = DiscoveryEngine::Quality::Evaluation.new(set).quality_metrics
        Rails.logger.info(quality_metrics)
        metric_collector.record_evaluations(quality_metrics, month_label, set.table_id)
      end
    end

    def sample_query_sets(month_label, table_id = nil)
      return DiscoveryEngine::Quality::SampleQuerySets.new(month_label).all if table_id.nil?

      DiscoveryEngine::Quality::SampleQuerySet.new(table_id:, month_label:)
    end
  end
end
