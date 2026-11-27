RSpec.describe DiscoveryEngine::Answer::Query do
  subject(:query) { described_class.new("my question") }

  let(:service) { instance_double(Google::Cloud::DiscoveryEngine::V1::ConversationalSearchService::Client) }
  let(:response) do
    Google::Cloud::DiscoveryEngine::V1::AnswerQueryResponse.new(
      answer: {
        answer_text: "You can stay forever.",
        citations: [
          { sources: [{ reference_id: "0" }, { reference_id: "1" }] },
          { sources: [{ reference_id: "0" }] },
        ],
        references: [
          { chunk_info: { document_metadata: { uri: "https://www.gov.uk/a" } } },
          { unstructured_document_info: { title: "B" } },
          { chunk_info: { document_metadata: { uri: "https://www.gov.uk/uncited" } } },
        ],
      },
    )
  end

  before do
    allow(DiscoveryEngine::Clients).to receive(:conversational_search_service).and_return(service)
    allow(service).to receive(:answer_query).and_return(response)
  end

  describe "#response" do
    it "queries the default serving config and returns the response" do
      expect(query.response).to eq(response)

      expect(service).to have_received(:answer_query).with(
        serving_config: ServingConfig.default.name,
        query: { text: "my question" },
      )
    end
  end

  describe "#answer_text" do
    it "returns the answer text" do
      expect(query.answer_text).to eq("You can stay forever.")
    end

    it "returns an empty string when there is no answer" do
      allow(service).to receive(:answer_query).and_return(Google::Cloud::DiscoveryEngine::V1::AnswerQueryResponse.new)
      expect(query.answer_text).to eq("")
    end
  end

  describe "#citations" do
    it "returns unique locations of cited references only" do
      expect(query.citations).to eq(["https://www.gov.uk/a", "B"])
    end

    it "returns an empty array when there is no answer" do
      allow(service).to receive(:answer_query).and_return(Google::Cloud::DiscoveryEngine::V1::AnswerQueryResponse.new)
      expect(query.citations).to eq([])
    end
  end
end
