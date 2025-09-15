module DiscoveryEngine::Quality
  class EvaluationsRunner
    MONTH_LABELS = %i[last_month month_before_last].freeze

    def initialize(table_id)
      @table_id = table_id
    end

    def upload_detailed_metrics
      evaluations.each do |e|
        detailed_metrics = e.list_evaluation_results
        send_to_bucket(detailed_metrics, e)
      end
    end

    def upload_and_report_metrics
      evaluations.each do |e|
        detailed_metrics = e.list_evaluation_results
        quality_metrics = e.quality_metrics
        send_to_bucket(detailed_metrics, e)
        send_to_prometheus(quality_metrics, e)
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

    def send_to_bucket(detailed_metrics, evaluation)
      time_stamp = evaluation.formatted_create_time
      partition_date = evaluation.partition_date

      gcp_bucket_exporter.send(
        time_stamp,
        table_id,
        partition_date,
        detailed_metrics,
      )
    end

    def send_to_prometheus(_quality_metrics, _evaluation)
      true
    end

    def gcp_bucket_exporter
      @gcp_bucket_exporter ||= DiscoveryEngine::Quality::GcpBucketExporter.new
    end
  end
end
