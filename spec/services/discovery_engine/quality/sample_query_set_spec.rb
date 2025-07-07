RSpec.describe DiscoveryEngine::Quality::SampleQuerySet do
  subject(:sample_query_set) { described_class.new(month_interval, table_id) }

  let(:month_interval) { DiscoveryEngine::Quality::MonthInterval.new(2025, 1) }

  let(:operation_object) { double("operation", wait_until_done!: true, error?: false) }
  let(:response_object) { double("response", name: "/sample_query_set/1") }
  let(:sample_query_set_service_stub) { double("sample_query_set_service", create_sample_query_set: response_object) }
  let(:sample_query_service_stub) { double("sample_query_service", import_sample_queries: operation_object) }
  let(:table_id) { "clickstream" }

  before do
    allow(DiscoveryEngine::Clients).to receive_messages(sample_query_set_service: sample_query_set_service_stub, sample_query_service: sample_query_service_stub)
  end

  describe "#create_and_import" do
    it "creates a sample query set for the given month interval" do
      sample_query_set.create_and_import

      expect(sample_query_set_service_stub).to have_received(:create_sample_query_set).with(
        sample_query_set: {
          display_name: "clickstream 2025-01",
          description: "Generated from 2025-01 BigQuery clickstream data",
        },
        sample_query_set_id: "clickstream_2025-01",
        parent: Rails.application.config.discovery_engine_default_location_name,
      )

      expect(sample_query_service_stub).to have_received(:import_sample_queries).with(
        parent: response_object.name,
        bigquery_source: {
          dataset_id: "automated_evaluation_input",
          table_id: "clickstream",
          project_id: Rails.application.config.google_cloud_project_id,
          partition_date: {
            year: 2025,
            month: 1,
            day: 1,
          },
        },
      )
    end

    context "when operation does not complete" do
      let(:error_stub) { double("error", message: "An error message") }
      let(:operation_object) { double("operation", wait_until_done!: true, error?: true, error: error_stub) }

      it "raises an error" do
        expect { sample_query_set.create_and_import }.to raise_error("An error message")
      end
    end
  end

  describe "#id" do
    it "returns the sample query set ID based on the month interval" do
      expect(sample_query_set.id).to eq("clickstream_2025-01")
    end
  end
end
