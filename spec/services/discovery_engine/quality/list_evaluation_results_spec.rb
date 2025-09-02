RSpec.describe DiscoveryEngine::Quality::ListEvaluationResults do
  describe "#raw_api_response" do
    let(:evaluation_name) { "projects/780375417592/locations/global/evaluations/2b53e0c6" }
    let(:sample_query_set_name) { "clickstream_09-2025" }
    let(:list_evaluation_results) { described_class.new(evaluation_name, sample_query_set_name) }
    let(:evaluation_service) { double("evaluation_service", list_evaluation_results: Gapic::PagedEnumerable) }

    before do
      allow(DiscoveryEngine::Clients)
        .to receive(:evaluation_service)
        .and_return(evaluation_service)
    end

    it "calls the list_evaluation_results endpoint and returns raw results" do
      expect(list_evaluation_results.raw_api_response).to eq(Gapic::PagedEnumerable)
    end
  end
end
