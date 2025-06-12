RSpec.describe DiscoveryEngine::Evaluation::EvaluationResource do
  let(:sample_set_id) { "clickstream_01_02" }
  let(:evaluation_resource) { described_class.new(sample_set_id) }

  let(:evaluation_service) { double("evaluation_service", create_evaluation: operation) }
  let(:operation) { double("operation", error?: false, wait_until_done!: true, results: response) }
  let(:response) { double("response", name: "/evaluations/1") }

  before do
    allow(DiscoveryEngine::Clients).to receive(:evaluation_service).and_return(evaluation_service)
    allow(Rails.logger).to receive(:info)
  end

  describe "#create_evaluation" do
    it "calls the create_evaluation endpoint" do
      evaluation_resource.create

      expect(evaluation_service).to have_received(:create_evaluation).with(
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

    context "when operation does not complete" do
      let(:error) { double("error", message: "An error message") }
      let(:operation) { double("operation", wait_until_done!: true, error?: true, error:) }

      it "raises an error" do
        expect { evaluation_resource.create }.to raise_error("An error message")
      end
    end
  end
end
