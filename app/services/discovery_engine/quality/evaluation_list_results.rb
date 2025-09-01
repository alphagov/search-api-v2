module DiscoveryEngine::Quality
  class EvaluationListResults
    def initialize(evaluation_name, sample_query_set_name)
      @evaluation_name = evaluation_name
      @sample_query_set_name = sample_query_set_name
    end

    attr_reader :evaluation_name, :sample_query_set_name

    def presented_results
      DiscoveryEngine::Quality::EvaluationListResultsPresenter
        .new(api_response.to_json)
        .formatted_for_biq_query
    end

  private

    def api_response
      results = DiscoveryEngine::Clients
        .evaluation_service
        .list_evaluation_results(
          evaluation: evaluation_name,
          page_size: 1000,
        )
      Rails.logger.info("Successfully fetched detailed metrics for #{sample_query_set_name}")
      results
    end
  end
end
