module QualityMonitoring
  class Runner
    attr_reader :file, :type, :cutoff, :report_query_below_score, :judge_by, :metric_collector

    def initialize(
      file,
      type,
      cutoff: 10,
      report_query_below_score: nil,
      judge_by: :recall,
      metric_collector: nil
    )
      @file = Pathname.new(file)
      @type = type

      @cutoff = cutoff
      @report_query_below_score = report_query_below_score
      @judge_by = judge_by
      @metric_collector = metric_collector
    end

    def run
      scores = []
      failure_details = []

      data.each do |query, expected_links|
        query_params = { q: query, page_size: cutoff }
        result_set = DiscoveryEngine::Query::Search.new(query_params).result_set
        result_links = result_set.results.map(&:link)

        judge = Judge.new(result_links, expected_links)
        score = judge.public_send(judge_by)

        scores << score
        next unless report_query_below_score && score < report_query_below_score

        missing_links = expected_links - judge.result_links
        failure_details << <<~DETAIL
          '#{query}' #{judge_by}:#{score} is below #{report_query_below_score}, missing:
            • #{missing_links.join("\n  • ")}
            -> Attribution token: #{result_set.discovery_engine_attribution_token}
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
      end

      if metric_collector
        metric_collector.record_score(type, dataset_name, mean_score)
        metric_collector.record_failure_count(type, dataset_name, failure_details.size)
        metric_collector.record_total_count(type, dataset_name, scores.size)
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
