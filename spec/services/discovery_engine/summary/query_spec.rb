RSpec.describe DiscoveryEngine::Summary::Query do
  subject(:query) { described_class.new("Can I apply?") }

  let(:service) { instance_double(Google::Cloud::DiscoveryEngine::V1::SearchService::Client) }
  let(:response) do
    Google::Cloud::DiscoveryEngine::V1::SearchResponse.new(
      results: [
        { document: { derived_struct_data: Google::Protobuf::Struct.from_hash(
          "extractive_answers" => [{ "content" => "Check your eligibility before applying." }],
        ) } },
        { document: {} },
      ],
      summary: {
        summary_text: "Check if you can apply [1].",
        summary_with_metadata: {
          references: [
            { uri: "https://www.gov.uk/first" },
            {},
            { uri: "https://www.gov.uk/second" },
            { uri: "https://www.gov.uk/first" },
          ],
        },
      },
    )
  end
  let(:empty_response) { Google::Cloud::DiscoveryEngine::V1::SearchResponse.new }

  before do
    allow(DiscoveryEngine::Clients).to receive(:search_service).and_return(service)
    allow(service).to receive(:search).and_return(double(response:))
  end

  describe "#response" do
    it "queries the default serving config and returns the response" do
      expect(query.response).to equal(response)

      expect(service).to have_received(:search).with(
        {
          page_size: DiscoveryEngine::Summary::Query::NUMBER_OF_RESULTS,
          serving_config: ServingConfig.default.name,
          query: "Can I apply?",
          content_search_spec: {
            summary_spec: { summary_result_count: DiscoveryEngine::Summary::Query::NUMBER_OF_RESULTS,
                            include_citations: true,
                            use_semantic_chunks: true },
            extractive_content_spec: { max_extractive_answer_count: 1 },
          },
        },
        timeout: 60,
      )
    end
  end

  describe "#summary_text" do
    it "returns the summary text" do
      expect(query.summary_text).to eq("Check if you can apply [1].")
    end

    it "returns an empty string when there is no summary" do
      allow(service).to receive(:search).and_return(double(response: empty_response))
      expect(query.summary_text).to eq("")
    end
  end

  describe "#extractive_answers" do
    it "returns extractive answer text from the results" do
      expect(query.extractive_answers).to eq(["Check your eligibility before applying."])
    end

    it "returns an empty array when there are no results" do
      allow(service).to receive(:search).and_return(double(response: empty_response))
      expect(query.extractive_answers).to be_empty
    end
  end

  describe "#citations" do
    it "returns unique nonblank URLs in reference order" do
      expect(query.citations).to eq(%w[https://www.gov.uk/first https://www.gov.uk/second])
    end

    it "returns an empty array when there is no summary" do
      allow(service).to receive(:search).and_return(double(response: empty_response))
      expect(query.citations).to be_empty
    end
  end
end
