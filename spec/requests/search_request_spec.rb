RSpec.describe "Making a search request" do
  let(:search_service) { instance_double(DiscoveryEngine::Query::Search, result_set:) }
  let(:result_set) { ResultSet.new(results:, total: 42, start: 21) }
  let(:results) { [Result.new(content_id: "123"), Result.new(content_id: "456")] }

  before do
    allow(DiscoveryEngine::Query::Search).to receive(:new).and_return(search_service)
  end

  describe "GET /search.json" do
    it "returns the result set as JSON" do
      get "/search.json"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        "results" => [
          { "content_id" => "123" },
          { "content_id" => "456" },
        ],
        "total" => 42,
        "start" => 21,
      })
    end

    it "passes any query parameters to the search service in the expected format" do
      get "/search.json?q=garden+centres&start=11&count=22&filter_public_timestamp=from:2019-01-01"

      expect(DiscoveryEngine::Query::Search).to have_received(:new).with(
        hash_including(
          q: "garden centres",
          start: "11",
          count: "22",
          filter_public_timestamp: "from:2019-01-01",
        ),
      )
    end
  end
end
