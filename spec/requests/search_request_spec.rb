RSpec.describe "Making a search request" do
  describe "GET /search.json" do
    it "returns HTTP 200 and an empty JSON object" do
      get "/search.json"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({})
    end
  end
end
