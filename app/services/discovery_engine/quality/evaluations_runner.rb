module DiscoveryEngine::Quality
  class EvaluationsRunner
    MONTH_LABELS = %i[last_month month_before_last].freeze

    def initialize(table_id)
      @table_id = table_id
    end

    def upload_and_report_metrics
      evaluations.each do |e|
        send_to_bucket(e)
        send_to_prometheus(e)
        # space out our calls to the evaluations API, as it is unable to handle concurrent requests
        Kernel.sleep(10)
      end
    end

  private

    attr_reader :table_id

    def evaluations
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
      Rails.logger.info(quality_metrics)

      # Skip pushing metrics to Prometheus in development, since push gateway is local to each
      # cluster (integration, staging or production)
      if Rails.env.development?
        Rails.logger.warn("Skipping push of evaluations to Prometheus push gateway")
      else
        month_label = evaluation.sample_set.month_label

        prometheus_reporter.send(
          quality_metrics,
          month_label,
          table_id,
        )
      end
    end

    def prometheus_reporter
      @prometheus_reporter ||= DiscoveryEngine::Quality::PrometheusReporter.new
    end
  end
end
