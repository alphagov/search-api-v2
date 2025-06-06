module DiscoveryEngine::Evaluation
  class ResultsRetriever
    def initialize(
      project_id: Rails.application.config.google_cloud_project_id,
      evaluation_client: ::Google::Cloud::DiscoveryEngine::V1beta::EvaluationService::Client.new
    )
      @project_id = project_id
      @evaluation_client = evaluation_client
    end

    def get_quality_metrics(evaluation_id)
      evaluation_name = "#{location}/evaluations/#{evaluation_id}"

      Rails.logger.info("Getting results for evaluation: #{evaluation_name}")

      evaluation = evaluation_client.get_evaluation(name: evaluation_name)

      if evaluation.state != :SUCCEEDED
        Rails.logger.warn("Evaluation is not in succeeded state: #{evaluation.state}")
      end

      evaluation.quality_metrics.to_h
    end

    def list_evaluation_results(evaluation_id, page_size: 50)
      evaluation_name = "#{location}/evaluations/#{evaluation_id}"

      evaluation_client.list_evaluation_results(
        parent: evaluation_name,
        page_size: page_size,
      )
    end

  private

    attr_reader :project_id, :evaluation_client

    def location
      @location ||= "projects/#{project_id}/locations/global"
    end
  end
end
