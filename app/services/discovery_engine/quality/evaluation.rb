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
      wait_for_active_evaluations_to_finish
      create_evaluation
      get_evaluation_with_wait(evaluation_name)
    end

    def wait_for_active_evaluations_to_finish
      return if active_evaluations.blank?

      active_evaluations.each do |e|
        Rails.logger.info("Waiting for #{e.name} to finish")
        while (e = get_evaluation(e.name))
          break if %i[SUCCEEDED FAILED].include?(e.state)

          Kernel.sleep(10)
        end
      end
    end

    def active_evaluations
      @active_evaluations ||=
        evaluation_service
          .list_evaluations(parent:)
          .select { |e| %i[PENDING RUNNING].include?(e.state) }
    end

    def create_evaluation
      operation = evaluation_service
        .create_evaluation(
          parent:,
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

    def get_evaluation_with_wait(name)
      Rails.logger.info("Fetching evaluations...")

      while (e = get_evaluation(name))
        return e if e.state == :SUCCEEDED

        Rails.logger.info("Still waiting for evaluation to complete...")
        Kernel.sleep(10)
      end
    end

    def get_evaluation(name)
      evaluation_service.get_evaluation(name:)
    end

    def evaluation_service
      @evaluation_service ||= DiscoveryEngine::Clients.evaluation_service
    end

    def parent
      @parent ||= Rails.application.config.discovery_engine_default_location_name
    end
  end
end
