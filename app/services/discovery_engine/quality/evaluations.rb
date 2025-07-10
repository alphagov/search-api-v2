module DiscoveryEngine::Quality
  class Evaluations
    MONTH_LABELS = %i[last_month month_before_last].freeze

    def initialize(metric_collector)
      @metric_collector = metric_collector
    end

    def collect_all_quality_metrics
      MONTH_LABELS.each { |month_label| collect_quality_metrics(month_label) }
    end

  private

    attr_reader :metric_collector

    def collect_quality_metrics(month_label)
      all_sample_query_sets(month_label).each do |set|
        e = DiscoveryEngine::Quality::Evaluation.new(set).fetch_quality_metrics
        Rails.logger.info(e)
        metric_collector.record_evaluations(e, month_label, set.table_id)
      end
    end

    def all_sample_query_sets(month_label)
      DiscoveryEngine::Quality::SampleQuerySets.new(month_label).all
    end
  end
end
