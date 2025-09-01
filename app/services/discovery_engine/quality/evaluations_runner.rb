module DiscoveryEngine::Quality
  class EvaluationsRunner
    MONTH_LABELS = %i[last_month month_before_last].freeze

    def initialize(table_id, prometheus_reporter, bigquery_reporter)
      @table_id = table_id
      @prometheus_reporter = prometheus_reporter
      @bigquery_reporter = bigquery_reporter
    end

    # Once a day at 7am
    ## Rake:quality:report_clickstream_quality_metrics
    ## EvaluationsRunner.new("clickstream").report_quality_metrics
    ## = 2 evaluations

    # Every 2hours weekdays 8-4pm
    ## Rake:quality:report_binary_quality_metrics
    ## EvaluationsRunner.new("binary").report_quality_metrics
    ## = 10 evaluations

    def report_quality_metrics
      evaluations.each do |e|
        aggregate_metrics = e.quality_metrics
        prometheus_reporter.send(e, aggregate_metrics)
      end
    end

    # Can be run on an adhoc basis
    def report_detailed_metrics
      evaluations.each do |e|
        detailed_metrics = e.list_evaluation_results
        bigquery_reporter.send(e, detailed_metrics)
      end
    end

    # Once a day at 7am or every 2 hours? Probably every 2 hours
    ## Rake:quality::report_all_explicit_metrics
    ## EvaluationsRunner.new("explicit").report_quality_metrics_and_detailed_metrics
    # question: do we actually need to send the detailed metrics for explicit datasets to prometheus?

    def report_quality_metrics_and_detailed_metrics
      evaluations.each do |e|
        aggregate_metrics = e.quality_metrics
        detailed_metrics = e.list_evaluation_results

        bigquery_reporter.send(e, detailed_metrics)
        prometheus_reporter.send(e, aggregate_metrics)
      end
    end

  private

    attr_reader :table_id, :bigquery_reporter, :prometheus_reporter

    def evaluations
      @evaluations ||=
        sample_query_sets(table_id).map { |set| DiscoveryEngine::Quality::Evaluation.new(set) }
    end

    # reinstate the logic to call sample_query_sets.all if there's no table_id
    def sample_query_sets(table_id)
      MONTH_LABELS.map do |month_label|
        DiscoveryEngine::Quality::SampleQuerySet.new(table_id:, month_label:)
      end
    end
  end
end
