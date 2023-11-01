RSpec.describe DiscoveryEngine::Search do
  subject(:search) { described_class.new(client:) }

  let(:client) { double("SearchService::Client", search: search_return_value) }

  before do
    allow(Rails.configuration).to receive(:discovery_engine_serving_config)
      .and_return("serving-config-path")
  end

  describe "#call" do
    context "when the search is successful" do
      subject!(:result_set) { search.call("garden centres") }

      let(:search_return_value) { double(response: search_response) }
      let(:search_response) { double(total_size: 42, results:) }
      let(:results) do
        [
          double(document: double(struct_data: { title: "Louth Garden Centre" })),
          double(document: double(struct_data: { title: "Cleethorpes Garden Centre" })),
        ]
      end

      it "calls the client with the expected parameters" do
        expect(client).to have_received(:search).with(
          serving_config: "serving-config-path",
          query: "garden centres",
          offset: 0,
          page_size: 10,
        )
      end

      it "returns a result set with the correct contents" do
        expect(result_set.start).to eq(0)
        expect(result_set.total).to eq(42)
        expect(result_set.results.map(&:title)).to eq([
          "Louth Garden Centre",
          "Cleethorpes Garden Centre",
        ])
      end

      context "when start and count are specified" do
        subject!(:result_set) { search.call("garden centres", start: 11, count: 22) }

        it "calls the client with the expected parameters" do
          expect(client).to have_received(:search).with(
            serving_config: "serving-config-path",
            query: "garden centres",
            offset: 11,
            page_size: 22,
          )
        end

        it "returns the specified start value in the result set" do
          expect(result_set.start).to eq(11)
        end
      end
    end
  end
end
