RSpec.describe DiscoveryEngine::Search do
  subject(:search) { described_class.new(client:) }

  let(:client) { double("SearchService::Client", search: search_return_value) }

  let(:expected_boost_specs) do
    [{ boost: 0.2,
       condition: "content_purpose_supergroup: ANY(\"news_and_communications\") AND public_timestamp: IN(628905600i,*)" },
     { boost: 0.05,
       condition: "content_purpose_supergroup: ANY(\"news_and_communications\") AND public_timestamp: IN(621644400i,628905600e)" },
     { boost: -0.5,
       condition: "content_purpose_supergroup: ANY(\"news_and_communications\") AND public_timestamp: IN(503280000i,597974400e)" },
     { boost: -0.75,
       condition: "content_purpose_supergroup: ANY(\"news_and_communications\") AND public_timestamp: IN(*,503280000e)" }]
  end

  before do
    allow(Rails.configuration).to receive(:discovery_engine_serving_config)
      .and_return("serving-config-path")
  end

  around do |example|
    Timecop.freeze(Time.zone.local(1989, 12, 13)) do
      example.run
    end
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
          boost_spec: { condition_boost_specs: expected_boost_specs },
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
            boost_spec: { condition_boost_specs: expected_boost_specs },
          )
        end

        it "returns the specified start value in the result set" do
          expect(result_set.start).to eq(11)
        end
      end
    end
  end
end
