module DiscoveryEngine::Quality
  class Evaluation
    attr_reader :sample_set

    def initialize(sample_set)
      @sample_set = sample_set
    end

    def quality_metrics
      fetched_evaluation.quality_metrics.to_h
    end

    # evaluation_name and fetched_evaluation.name are equivalent, but calling fetched_evaluation
    # ensures that we have fetched an evaluation before we ask for list_results.
    def list_evaluation_results
      ListEvaluationResults.new(
        fetched_evaluation.name,
        sample_set.display_name,
        serving_config,
      ).formatted_json
    end

    def formatted_create_time
      raise "Error: cannot provide create time of an evaluation unless one exists" if @fetched_evaluation.blank?

      google_time_stamp = @fetched_evaluation.create_time
      if google_time_stamp
        data = { nanos: google_time_stamp.nanos, seconds: google_time_stamp.seconds }
        Google::Protobuf::Timestamp.new(data).to_time.strftime("%Y-%m-%d %H:%M:%S")
      end
    end

  private

    attr_reader :evaluation_name

    def serving_config
      raise "Error: cannot provide serving config of an evaluation unless one exists" if @fetched_evaluation.blank?

      @fetched_evaluation.evaluation_spec.search_request.serving_config
    end

    def fetched_evaluation
      @fetched_evaluation ||= fetch_evaluation
    end

    def fetch_evaluation
      create_evaluation
      get_evaluation_with_wait
    end

    def create_evaluation
      operation = evaluation_service
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
      GovukError.notify("No evaluation created of sample set #{sample_set.display_name} (#{e})")
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
      evaluation_service.get_evaluation(name: evaluation_name)
    end

    def evaluation_service
      @evaluation_service ||= DiscoveryEngine::Clients.evaluation_service
    end
  end
end
