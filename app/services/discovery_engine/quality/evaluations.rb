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
        e = DiscoveryEngine::Quality::Evaluation.new(set).fetch_quality_metrics
        Rails.logger.info(e)
        metric_collector.record_evaluations(e, month_label, set.table_id)
      rescue Google::Cloud::AlreadyExistsError
        GovukError.notify("No evaluation created for sample query set #{set.name}. Month label: '#{month_label}')")
      end
    end

    def sample_query_sets(month_label, table_id = nil)
      return DiscoveryEngine::Quality::SampleQuerySets.new(month_label).all if table_id.nil?

      DiscoveryEngine::Quality::SampleQuerySet.new(table_id:, month_label:)
    end
  end
end
