require "repositories/google_discovery_engine/read_repository"

# Require v1 specifically to instance_double it (repository itself uses non-versioned API)
require "google/cloud/discovery_engine/v1"

RSpec.describe Repositories::GoogleDiscoveryEngine::ReadRepository do
  let(:repository) do
    described_class.new(
      "serving-config-path",
      client:,
      logger:,
    )
  end
  let(:client) { instance_double(Google::Cloud::DiscoveryEngine::V1::SearchService::Client) }
  let(:logger) { instance_double(Logger) }

  describe "#search" do
    let(:search_return_value) { double(response: search_response) }
    let(:search_response) { double(total_size: 42, results:) }
    let(:results) do
      [
        double(document: double(struct_data: { foo: "bar" })),
        double(document: double(struct_data: { foo: "baz" })),
      ]
    end

    before do
      allow(client).to receive(:search).and_return(search_return_value)
    end

    it "performs a search" do
      search = repository.search("garden centres", start: 11, count: 22)

      expect(client).to have_received(:search).with(
        serving_config: "serving-config-path",
        query: "garden centres",
        offset: 11,
        page_size: 22,
      )

      expect(search.total).to eq(42)
      expect(search.results).to eq([
        { foo: "bar" },
        { foo: "baz" },
      ])
    end
  end
end
