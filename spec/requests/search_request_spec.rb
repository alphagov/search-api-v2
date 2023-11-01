RSpec.describe "Making a search request" do
  let(:search_service) { instance_double(DiscoveryEngine::Search, call: result_set) }
  let(:result_set) { ResultSet.new(results: [], total: 42, start: 21) }

  before do
    allow(DiscoveryEngine::Search).to receive(:new).and_return(search_service)
  end

  describe "GET /search.json" do
    it "returns the result set as JSON" do
      get "/search.json"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        "results" => [],
        "total" => 42,
        "start" => 21,
      })
    end

    it "passes any query parameters to the search service in the expected format" do
      get "/search.json?q=garden+centres&start=11&count=22"

      expect(search_service).to have_received(:call).with("garden centres", start: 11, count: 22)
    end
  end
end
