RSpec.describe DiscoveryEngine::Evaluation::EvaluationRunner do
  subject(:runner) do
    described_class.new(
      project_id: project_id,
      evaluation_client: evaluation_client,
    )
  end

  let(:project_id) { "test-project" }
  let(:evaluation_client) { instance_double(Google::Cloud::DiscoveryEngine::V1beta::EvaluationService::Client) }
  let(:location) { "projects/test-project/locations/global" }

  before do
    allow(Kernel).to receive(:sleep).and_return(nil)
  end

  describe "#create_evaluation" do
    let(:sample_query_set_id) { "clickstream_2025-04" }
    let(:sample_set_name) { "#{location}/sampleQuerySets/#{sample_query_set_id}" }
    let(:evaluation) { double("evaluation", name: "#{location}/evaluations/test-evaluation-id") }
    let(:operation) { double("operation", wait_until_done!: nil, error?: false, results: evaluation) }

    before do
      allow(evaluation_client).to receive(:create_evaluation).and_return(operation)
      allow(ServingConfig).to receive(:default).and_return(double(name: "default-serving-config"))
    end

    it "creates an evaluation with correct parameters" do
      runner.create_evaluation(sample_query_set_id)

      expect(evaluation_client).to have_received(:create_evaluation).with(
        parent: location,
        evaluation: {
          evaluation_spec: {
            query_set_spec: {
              sample_query_set: sample_set_name,
            },
            search_request: {
              serving_config: "default-serving-config",
            },
          },
        },
      )
    end

    it "waits for operation to complete" do
      runner.create_evaluation(sample_query_set_id)

      expect(operation).to have_received(:wait_until_done!)
    end

    it "returns the created evaluation" do
      result = runner.create_evaluation(sample_query_set_id)

      expect(result).to eq(evaluation)
    end

    context "when operation fails" do
      let(:error_message) { "Something went wrong" }
      let(:operation) do
        double("operation", wait_until_done!: nil, error?: true, error: double(message: error_message))
      end

      it "raises an error with the operation error message" do
        expect { runner.create_evaluation(sample_query_set_id) }.to raise_error(StandardError, "Error creating evaluation: #{error_message}")
      end
    end
  end

  describe "#wait_for_completion" do
    let(:evaluation_id) { "test-evaluation-id" }
    let(:evaluation_name) { "#{location}/evaluations/#{evaluation_id}" }

    context "when evaluation succeeds immediately" do
      let(:evaluation) { double("evaluation", state: :SUCCEEDED) }

      before do
        allow(evaluation_client).to receive(:get_evaluation).and_return(evaluation)
      end

      it "returns the completed evaluation" do
        result = runner.wait_for_completion(evaluation_id)

        expect(evaluation_client).to have_received(:get_evaluation).with(name: evaluation_name)
        expect(result).to eq(evaluation)
      end
    end

    context "when evaluation is pending then succeeds" do
      let(:pending_evaluation) { double("evaluation", state: :PENDING) }
      let(:completed_evaluation) { double("evaluation", state: :SUCCEEDED) }

      before do
        allow(evaluation_client).to receive(:get_evaluation).and_return(pending_evaluation, completed_evaluation)
      end

      it "polls until completion" do
        result = runner.wait_for_completion(evaluation_id)

        expect(evaluation_client).to have_received(:get_evaluation).twice
        expect(result).to eq(completed_evaluation)
      end
    end

    context "when evaluation fails" do
      let(:failed_evaluation) { double("evaluation", state: :FAILED) }

      before do
        allow(evaluation_client).to receive(:get_evaluation).and_return(failed_evaluation)
      end

      it "raises an error" do
        expect { runner.wait_for_completion(evaluation_id) }.to raise_error(StandardError, "Evaluation failed")
      end
    end

    context "when evaluation has unknown state" do
      let(:unknown_evaluation) { double("evaluation", state: :UNKNOWN) }
      let(:completed_evaluation) { double("evaluation", state: :SUCCEEDED) }

      before do
        allow(evaluation_client).to receive(:get_evaluation).and_return(unknown_evaluation, completed_evaluation)
      end

      it "continues polling" do
        result = runner.wait_for_completion(evaluation_id)

        expect(evaluation_client).to have_received(:get_evaluation).twice
        expect(Kernel).to have_received(:sleep).with(10.seconds)
        expect(result).to eq(completed_evaluation)
      end
    end
  end

  describe "#get_evaluation" do
    let(:evaluation_id) { "test-evaluation-id" }
    let(:evaluation_name) { "#{location}/evaluations/#{evaluation_id}" }
    let(:evaluation) { double("evaluation") }

    before do
      allow(evaluation_client).to receive(:get_evaluation).and_return(evaluation)
    end

    it "retrieves the evaluation" do
      result = runner.get_evaluation(evaluation_id)

      expect(evaluation_client).to have_received(:get_evaluation).with(name: evaluation_name)
      expect(result).to eq(evaluation)
    end
  end

  describe "#list_all" do
    let(:evaluations) { double("evaluations") }

    before do
      allow(evaluation_client).to receive(:list_evaluations).and_return(evaluations)
    end

    it "lists all evaluations" do
      result = runner.list_all

      expect(evaluation_client).to have_received(:list_evaluations).with(parent: location)
      expect(result).to eq(evaluations)
    end
  end
end
