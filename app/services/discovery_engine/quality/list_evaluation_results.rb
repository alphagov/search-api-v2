module DiscoveryEngine::Quality
  class ListEvaluationResults
    def initialize(evaluation_name, sample_query_set_name, serving_config)
      @evaluation_name = evaluation_name
      @sample_query_set_name = sample_query_set_name
      @serving_config = serving_config
    end

    def formatted_json
      json = raw_api_response.to_json
      parsed = JSON.parse(json)
      with_required_keys = {
        "evaluation_name" => evaluation_name,
        "serving_configuration_name" => serving_config_display_name,
        "evaluation_results" => parsed,
      }
      with_required_keys.to_json
    end

  private

    attr_reader :evaluation_name, :sample_query_set_name, :serving_config

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

    def serving_config_display_name
      serving_config.split("/")[-1]
    end
  end
end
