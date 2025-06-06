RSpec.describe DiscoveryEngine::Evaluation::ResultsRetriever do
  subject(:retriever) do
    described_class.new(
      project_id: project_id,
      evaluation_client: evaluation_client,
    )
  end

  let(:project_id) { "test-project" }
  let(:evaluation_client) { instance_double(Google::Cloud::DiscoveryEngine::V1beta::EvaluationService::Client) }
  let(:location) { "projects/test-project/locations/global" }

  describe "#get_quality_metrics" do
    let(:evaluation_id) { "test-evaluation-id" }
    let(:evaluation_name) { "#{location}/evaluations/#{evaluation_id}" }
    let(:quality_metrics) { double("quality_metrics", to_h: { "precision" => 0.85, "recall" => 0.72 }) }
    let(:evaluation) { double("evaluation", state: :SUCCEEDED, quality_metrics: quality_metrics) }

    before do
      allow(evaluation_client).to receive(:get_evaluation).and_return(evaluation)
    end

    it "retrieves quality metrics for the evaluation" do
      result = retriever.get_quality_metrics(evaluation_id)

      expect(evaluation_client).to have_received(:get_evaluation).with(name: evaluation_name)
      expect(result).to eq({ "precision" => 0.85, "recall" => 0.72 })
    end

    context "when evaluation is not in succeeded state" do
      let(:evaluation) { double("evaluation", state: :PENDING, quality_metrics: quality_metrics) }

      it "still returns quality metrics but logs a warning" do
        allow(Rails.logger).to receive(:warn)

        result = retriever.get_quality_metrics(evaluation_id)

        expect(Rails.logger).to have_received(:warn).with("Evaluation is not in succeeded state: PENDING")
        expect(result).to eq({ "precision" => 0.85, "recall" => 0.72 })
      end
    end
  end

  describe "#list_evaluation_results" do
    let(:evaluation_id) { "test-evaluation-id" }
    let(:evaluation_name) { "#{location}/evaluations/#{evaluation_id}" }
    let(:evaluation_results) { double("evaluation_results") }

    before do
      allow(evaluation_client).to receive(:list_evaluation_results).and_return(evaluation_results)
    end

    it "lists evaluation results with default page size" do
      result = retriever.list_evaluation_results(evaluation_id)

      expect(evaluation_client).to have_received(:list_evaluation_results).with(
        parent: evaluation_name,
        page_size: 50,
      )
      expect(result).to eq(evaluation_results)
    end

    it "lists evaluation results with custom page size" do
      result = retriever.list_evaluation_results(evaluation_id, page_size: 100)

      expect(evaluation_client).to have_received(:list_evaluation_results).with(
        parent: evaluation_name,
        page_size: 100,
      )
      expect(result).to eq(evaluation_results)
    end
  end
end
