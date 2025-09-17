module DiscoveryEngine::Quality
  class EvaluationsRunner
    MONTH_LABELS = %i[last_month month_before_last].freeze

    def initialize(table_id)
      @table_id = table_id
    end

    def upload_detailed_metrics
      evaluations.each do |e|
        send_to_bucket(e)
        send_to_prometheus(e)
      end
    end

  private

    attr_reader :table_id

    def evaluations
      @evaluations ||=
        sample_query_sets(table_id).map { |set| DiscoveryEngine::Quality::Evaluation.new(set) }
    end

    def sample_query_sets(table_id)
      MONTH_LABELS.map do |month_label|
        DiscoveryEngine::Quality::SampleQuerySet.new(table_id:, month_label:)
      end
    end

    def send_to_bucket(evaluation)
      # list_evaluation_results must be called first as this method
      # creates the evaluation.
      detailed_metrics = evaluation.list_evaluation_results
      time_stamp = evaluation.formatted_create_time
      partition_date = evaluation.sample_set.partition_date

      gcp_bucket_exporter.send(
        time_stamp,
        table_id,
        partition_date,
        detailed_metrics,
      )
    end

    def gcp_bucket_exporter
      @gcp_bucket_exporter ||= DiscoveryEngine::Quality::GcpBucketExporter.new
    end

    def send_to_prometheus(evaluation)
      quality_metrics = evaluation.quality_metrics
      prometheus_reporter.send(quality_metrics, "label", "label")
    end

    def prometheus_reporter
      @prometheus_reporter ||= DiscoveryEngine::Quality::PrometheusReporter.new
    end
  end
end
