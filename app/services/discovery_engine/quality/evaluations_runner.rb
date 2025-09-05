module DiscoveryEngine::Quality
  class EvaluationsRunner
    MONTH_LABELS = %i[last_month month_before_last].freeze

    def initialize(table_id)
      @table_id = table_id
    end

    def upload_detailed_metrics
      evaluations.each do |e|
        detailed_metrics = e.list_evaluation_results
        time_stamp = e.formatted_create_time
        partition_date = e.full_partition_date
        gcp_bucket_exporter.send(
          time_stamp,
          table_id,
          partition_date,
          detailed_metrics,
        )
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

    def gcp_bucket_exporter
      @gcp_bucket_exporter ||= DiscoveryEngine::Quality::GcpBucketExporter.new
    end
  end
end
