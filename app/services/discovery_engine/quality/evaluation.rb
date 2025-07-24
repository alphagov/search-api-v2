module DiscoveryEngine::Quality
  class Evaluation
    MAX_RETRIES_ON_ERROR = 3
    WAIT_ON_ERROR = 3

    def initialize(sample_set)
      @sample_set = sample_set
      @attempt = 1
    end

    def fetch_quality_metrics
      create
      fetch
    end

  private

    attr_reader :sample_set, :result

    def create
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

      Rails.logger.info("Successfully created evaluation #{result.name}")
    rescue Google::Cloud::AlreadyExistsError => e
      if @attempt < MAX_RETRIES_ON_ERROR
        Rails.logger.warn("Failed to create evaluation (#{e.message}). Retrying...")
        @attempt += 1
        Kernel.sleep(WAIT_ON_ERROR)
        retry
      else
        raise e
      end
    end

    def fetch
      Rails.logger.info("Fetching evaluations...")
      fetch_with_wait.quality_metrics.to_h
    end

    def fetch_with_wait
      while (e = fetch_evaluation)
        return e if e.state == :SUCCEEDED

        Rails.logger.info("Still waiting for evaluation to complete...")
        Kernel.sleep(10)
      end
    end

    def fetch_evaluation
      DiscoveryEngine::Clients.evaluation_service.get_evaluation(name: result.name)
    end
  end
end
