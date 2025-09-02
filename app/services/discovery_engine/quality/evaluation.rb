module DiscoveryEngine::Quality
  class Evaluation
    def initialize(sample_set)
      @sample_set = sample_set
    end

    def quality_metrics
      @quality_metrics ||= api_response.quality_metrics.to_h
    end

  private

    attr_reader :sample_set, :result

    def api_response
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

      @result = operation.results

      Rails.logger.info("Successfully created evaluation: #{sample_set.display_name}")
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
      DiscoveryEngine::Clients.evaluation_service.get_evaluation(name: result.name)
    end
  end
end
