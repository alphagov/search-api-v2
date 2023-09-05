RSpec.describe "Making a search request" do
  describe "GET /search.json" do
    it "successfully returns a minimally acceptable zero results response for finder-frontend" do
      get "/search.json"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        "results" => [],
        "total" => 0,
        "start" => 0,
      })
    end
  end
end
