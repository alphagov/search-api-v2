module DiscoveryEngine
  module Evaluation
    class EvaluationResource
      attr_reader :sample_set_id

      def initialize(sample_set_id)
        @sample_set_id = sample_set_id
      end

      def fetch_quality_metrics
        create
        fetch_and_output_metrics
      end

    private

      attr_reader :evaluation

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

        @evaluation = operation.results

        Rails.logger.info("Successfully created evaluation #{evaluation.name}")
      end

      def fetch_and_output_metrics
        # TODO: implement a new method in the Metrics::Exported module to send quality metrics to Prometheus instead
        Rails.logger.info(fetch_with_wait.quality_metrics.to_h)
      end

      def sample_set_name
        "#{Rails.application.config.discovery_engine_default_location_name}/sampleQuerySets/#{sample_set_id}"
      end

      def fetch_with_wait
        while (e = fetch_evaluation)
          return e if e.state == :SUCCEEDED

          Rails.logger.info("Still waiting for evaluation to complete...")
          Kernel.sleep(10)
        end
      end

      def fetch_evaluation
        DiscoveryEngine::Clients.evaluation_service.get_evaluation(name: evaluation.name)
      end
    end
  end
end
