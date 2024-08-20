RSpec.describe "Making an autocomplete request" do
  let(:autocomplete_service) { instance_double(DiscoveryEngine::Autocomplete::Complete, completion_result:) }
  let(:completion_result) { CompletionResult.new(suggestions: %w[foo foobar foobaz]) }

  before do
    allow(DiscoveryEngine::Autocomplete::Complete).to receive(:new)
      .with("foo").and_return(autocomplete_service)
  end

  describe "GET /autocomplete.json" do
    it "returns a set of suggestions as JSON" do
      get "/autocomplete.json?q=foo"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        "suggestions" => %w[foo foobar foobaz],
      })
    end
  end
end