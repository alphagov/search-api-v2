module DiscoveryEngine
  module Evaluation
    class EvaluationResource
      attr_reader :sample_set_id

      def initialize(sample_set_id)
        @sample_set_id = sample_set_id
      end

      def create
        operation = DiscoveryEngine::Clients
          .evaluation_service
          .create_evaluation(
            parent: Rails.application.config.discovery_engine_default_location_name,
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

        raise operation.error.message.to_s if operation.error?

        evaluation = operation.results

        Rails.logger.info("Successfully created evaluation #{evaluation.name}")
      end

    private

      def sample_set_name
        "#{Rails.application.config.discovery_engine_default_location_name}/sampleQuerySets/#{sample_set_id}"
      end
    end
  end
end
