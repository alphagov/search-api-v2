RSpec.describe DiscoveryEngine::Evaluation::SampleQuerySet do
  subject(:sample_query_set) { described_class }

  let(:month) { "1" }
  let(:year) { "2025" }
  let(:sample_query_set_service_stub) { double("sample_query_set_service", create_sample_query_set: true) }

  before do
    allow(DiscoveryEngine::Clients).to receive(:sample_query_set_service).and_return(sample_query_set_service_stub)
  end

  describe ".create" do
    it "calls the create sample query set endpoint" do
      sample_query_set.create(month:, year:)

      expect(sample_query_set_service_stub).to have_received(:create_sample_query_set).with(
        sample_query_set: {
          display_name: "Clickstream #{year}-#{month}",
          description: "Generated from #{year}-#{month} BigQuery clickstream data",
        },
        sample_query_set_id: "clickstream_#{year}-#{month}",
        parent: Rails.application.config.discovery_engine_default_location_name,
      )
    end
  end
end
