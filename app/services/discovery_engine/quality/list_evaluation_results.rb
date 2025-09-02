module DiscoveryEngine::Quality
  class ListEvaluationResults
    def initialize(evaluation_name, sample_query_set_name)
      @evaluation_name = evaluation_name
      @sample_query_set_name = sample_query_set_name
    end

    attr_reader :evaluation_name, :sample_query_set_name

    def raw_api_response
      results = DiscoveryEngine::Clients
        .evaluation_service
        .list_evaluation_results(
          evaluation: evaluation_name,
          page_size: 1000,
        )
      Rails.logger.info("Successfully fetched detailed metrics for evaluation #{evaluation_name} of sample query set #{sample_query_set_name}")
      results
    end
  end
end
