module DiscoveryEngine::Quality
  class Evaluation
    def initialize(sample_set)
      @sample_set = sample_set
    end

    def quality_metrics
      api_response.quality_metrics.to_h
    end

    # evaluation_name and api_response.name are equivalent, but calling api_response
    # ensures that we have fetched an evaluation before we ask for list_results.
    def list_evaluation_results
      ListEvaluationResults.new(api_response.name, sample_set.display_name).formatted_json
    end

  private

    attr_reader :sample_set, :evaluation_name

    def api_response
      @api_response ||= fetch_api_response
    end

    def fetch_api_response
      create_evaluation
      get_evaluation_with_wait
    end

    def create_evaluation
      operation = DiscoveryEngine::Clients
        .evaluation_service
        .create_evaluation(
          parent: Rails.application.config.discovery_engine_default_location_name,
          evaluation: {
            evaluation_spec: {
              query_set_spec: {
                sample_query_set: sample_set.name,
              },
              search_request: {
                serving_config: ServingConfig.default.name,
              },
            },
          },
        )
      operation.wait_until_done!

      raise operation.error.message.to_s if operation.error?

      @evaluation_name = operation.results.name

      Rails.logger.info("Successfully created an evaluation of sample set #{sample_set.display_name}")
    rescue Google::Cloud::AlreadyExistsError => e
      Rails.logger.warn("Failed to create an evaluation of sample set #{sample_set.display_name} (#{e.message})")
      raise e
    end

    def get_evaluation_with_wait
      Rails.logger.info("Fetching evaluations...")

      while (e = get_evaluation)
        return e if e.state == :SUCCEEDED

        Rails.logger.info("Still waiting for evaluation to complete...")
        Kernel.sleep(10)
      end
    end

    def get_evaluation
      DiscoveryEngine::Clients.evaluation_service.get_evaluation(name: evaluation_name)
    end
  end
end
