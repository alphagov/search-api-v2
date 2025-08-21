module DiscoveryEngine::Quality
  class Evaluation
    MAX_RETRIES_ON_ERROR = 3
    WAIT_ON_ERROR = 3

    delegate :table_id, :month_label, :month, :year, to: :sample_set

    def initialize(sample_set)
      @sample_set = sample_set
      @attempt = 1
    end

    def quality_metrics
      @quality_metrics ||= api_response.quality_metrics.to_h
    end

    def list_evaluation_results
      # raise "Detailed metrics aren't available yet" if result.nil?

      @list_evaluation_results ||=
        DiscoveryEngine::Clients
          .evaluation_service
          .list_evaluation_results(
            evaluation: result.try(:name) || api_response.name,
            page_size: 1000,
          )
      Rails.logger.info("Successfully fetched detailed metrics for #{sample_set.name}")
    end

    def create_time
      api_response.create_time
    end

  private

    attr_reader :sample_set, :result

    def api_response
      @api_response ||=
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
