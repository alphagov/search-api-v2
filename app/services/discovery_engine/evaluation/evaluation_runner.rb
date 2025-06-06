module DiscoveryEngine::Evaluation
  class EvaluationRunner
    POLLING_INTERVAL = 10.seconds

    def initialize(
      project_id: Rails.application.config.google_cloud_project_id,
      evaluation_client: ::Google::Cloud::DiscoveryEngine::V1beta::EvaluationService::Client.new
    )
      @project_id = project_id
      @evaluation_client = evaluation_client
    end

    def create_evaluation(sample_query_set_id)
      sample_set_name = "#{location}/sampleQuerySets/#{sample_query_set_id}"

      Rails.logger.info("Creating evaluation for sample query set: #{sample_set_name}")

      operation = evaluation_client.create_evaluation(
        parent: location,
        evaluation: {
          evaluation_spec: {
            query_set_spec: {
              sample_query_set: sample_set_name,
            },
            search_request: {
              serving_config: ServingConfig.default.name,
            },
          },
        },
      )

      operation.wait_until_done!

      if operation.error?
        error_message = "Error creating evaluation: #{operation.error.message}"
        Rails.logger.error(error_message)
        raise StandardError, error_message
      end

      evaluation = operation.results
      Rails.logger.info("Successfully created evaluation #{evaluation.name}")

      evaluation
    end

    def wait_for_completion(evaluation_id)
      evaluation_name = "#{location}/evaluations/#{evaluation_id}"

      Rails.logger.info("Waiting for evaluation to complete: #{evaluation_name}")

      loop do
        evaluation = evaluation_client.get_evaluation(name: evaluation_name)

        case evaluation.state
        when :PENDING
          Rails.logger.info("Still waiting for evaluation to complete...")
          Kernel.sleep POLLING_INTERVAL
        when :SUCCEEDED
          Rails.logger.info("Evaluation completed successfully")
          return evaluation
        when :FAILED
          error_message = "Evaluation failed"
          Rails.logger.error(error_message)
          raise StandardError, error_message
        else
          Rails.logger.warn("Unknown evaluation state: #{evaluation.state}")
          Kernel.sleep POLLING_INTERVAL
        end
      end
    end

    def get_evaluation(evaluation_id)
      evaluation_name = "#{location}/evaluations/#{evaluation_id}"
      evaluation_client.get_evaluation(name: evaluation_name)
    end

    def list_all
      evaluation_client.list_evaluations(parent: location)
    end

  private

    attr_reader :project_id, :evaluation_client

    def location
      @location ||= "projects/#{project_id}/locations/global"
    end
  end
end
