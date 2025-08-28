module DiscoveryEngine::Quality
  class EvaluationsRunner
    MONTH_LABELS = %i[last_month month_before_last].freeze

    def initialize(table_id, prometheus_reporter, bigquery_reporter)
      @table_id = table_id
      @prometheus_reporter = prometheus_reporter
      @bigquery_reporter = bigquery_reporter
    end

    def report_aggregate_metrics
      evaluations.each do |e|
        prometheus_reporter.send(e)
      end
    end

    def report_detailed_metrics
      evaluations.each do |e|
        bigquery_reporter.send(e)
      end
    end

    def report_all_metrics
      evaluations.each do |e|
        bigquery_reporter.send(e)
        prometheus_reporter.send(e)
      end
    end

  private

    attr_reader :table_id, :bigquery_reporter, :prometheus_reporter

    def evaluations
      @evaluations ||= begin
        sample_query_sets(table_id).map do |set|
          DiscoveryEngine::Quality::Evaluation.new(set)
        end
      rescue Google::Cloud::AlreadyExistsError
        # amend to display_name once that's public
        GovukError.notify("No evaluation created for sample query set #{set.name}")
      end
    end

    # reinstate the logic to call sample_query_sets.all if there's no table_id
    def sample_query_sets(table_id)
      MONTH_LABELS.map do |month_label|
        DiscoveryEngine::Quality::SampleQuerySet.new(table_id:, month_label:)
      end
    end
  end
end
