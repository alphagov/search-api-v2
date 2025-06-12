RSpec.describe DiscoveryEngine::Evaluation::EvaluationResource do
  let(:sample_set_id) { "clickstream_01_02" }
  let(:evaluation_resource) { described_class.new(sample_set_id) }

  let(:evaluation_service_stub) { double("evaluation_service", create_evaluation: operation_object, get_evaluation: evaluation_object) }
  let(:operation_object) { double("operation", error?: false, wait_until_done!: true, results: response_object) }
  let(:response_object) { double("response", name: "/evaluations/1") }
  let(:evaluation_object) { double("evaluation", state: :SUCCEEDED, quality_metrics: quality_metrics_object) }
  let(:quality_metrics_object) { double("quality_metrics", to_h: "some output") }

  before do
    allow(DiscoveryEngine::Clients).to receive(:evaluation_service).and_return(evaluation_service_stub)
    allow(Rails.logger).to receive(:info)
  end

  describe "#fetch_quality_metrics" do
    it "calls the create_evaluation endpoint" do
      evaluation_resource.fetch_quality_metrics

      expect(evaluation_service_stub).to have_received(:create_evaluation).with(
        parent: Rails.application.config.discovery_engine_default_location_name,
        evaluation: {
          evaluation_spec: {
            query_set_spec: {
              sample_query_set: "#{Rails.application.config.discovery_engine_default_location_name}/sampleQuerySets/#{sample_set_id}",
            },
            search_request: {
              serving_config: ServingConfig.default.name,
            },
          },
        },
      )

      expect(Rails.logger).to have_received(:info)
        .with("Successfully created evaluation /evaluations/1")
    end

    it "polls the get_evaluation endpoint until state == :SUCCEEDED" do
      evaluation_resource.fetch_quality_metrics

      expect(evaluation_service_stub)
        .to have_received(:get_evaluation)
        .with(name: response_object.name)
        .twice

      expect(evaluation_object)
        .to have_received(:quality_metrics)
        .once
    end

    context "when operation does not complete" do
      let(:error_stub) { double("error", message: "An error message") }
      let(:operation_object) { double("operation", wait_until_done!: true, error?: true, error: error_stub) }

      it "raises an error" do
        expect { evaluation_resource.fetch_quality_metrics }.to raise_error("An error message")
      end
    end
  end
end
