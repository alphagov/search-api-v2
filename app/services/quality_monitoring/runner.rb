module QualityMonitoring
  class Runner
    class FailuresEncountered < StandardError; end

    attr_reader :file, :type, :cutoff, :report_query_below_score, :judge_by

    def initialize(file, type, cutoff: 10, report_query_below_score: nil, judge_by: :recall)
      @file = Pathname.new(file)
      @type = type

      @cutoff = cutoff
      @report_query_below_score = report_query_below_score
      @judge_by = judge_by
    end

    def run
      scores = []
      failure_details = []

      data.each do |query, expected_links|
        judge = Judge.for_query(query, expected_links, cutoff:)
        score = judge.public_send(judge_by)

        scores << score
        next unless report_query_below_score && score < report_query_below_score

        missing_links = expected_links - judge.result_links
        failure_details << <<~DETAIL
          '#{query}' #{judge_by}:#{score} is below #{report_query_below_score}, missing:
            • #{missing_links.join("\n  • ")}
        DETAIL
      rescue StandardError => e
        GovukError.notify(e)
      end

      mean_score = scores.sum / scores.size.to_f
      Rails.logger.info(
        sprintf(
          "[%s] Completed run for %s dataset %s with %s:%f",
          self.class.name,
          type,
          dataset_name,
          judge_by,
          mean_score,
        ),
      )
      # TODO: Send to Prometheus as `quality_monitoring_score{dataset: dataset_name, type: type}`

      if failure_details.any?
        Rails.logger.warn(
          sprintf(
            "[%s] %d failure(s) encountered for %s dataset %s\n%s",
            self.class.name,
            failure_details.size,
            type,
            dataset_name,
            failure_details.join("\n"),
          ),
        )

        err = FailuresEncountered.new(
          "Quality monitoring: #{failure_details.size} failures encountered " \
          "for #{type} dataset #{dataset_name}",
        )
        GovukError.notify(
          err,
          extra: { dataset_name:, type:, failure_details: failure_details.join("\n") },
        )
      end
    end

  private

    def dataset_name
      file.basename(".csv").to_s
    end

    def data
      @data ||= DatasetLoader.new(file).data
    end
  end
end
