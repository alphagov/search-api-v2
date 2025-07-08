module DiscoveryEngine::Quality
  class Evaluations
    def initialize(month_label, metric_collector)
      @month_label = month_label
      @metric_collector = metric_collector
    end

    attr_reader :metric_collector

    def collect_all_quality_metrics
      all_sample_query_sets.each do |set|
        e = DiscoveryEngine::Quality::Evaluation.new(set).fetch_quality_metrics
        Rails.logger.info(e)
        metric_collector.record_evaluations(e, month_label)
      end
    end

  private

    attr_reader :month_label

    def month_interval
      case month_label

      when :last_month
        DiscoveryEngine::Quality::MonthInterval.previous_month
      when :month_before_last
        DiscoveryEngine::Quality::MonthInterval.previous_month(2)
      end
    end

    def all_sample_query_sets
      DiscoveryEngine::Quality::SampleQuerySets.new(month_interval).all
    end
  end
end
