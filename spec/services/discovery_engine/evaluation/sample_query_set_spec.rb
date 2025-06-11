RSpec.describe DiscoveryEngine::Evaluation::SampleQuerySet do
  subject(:sample_query_set) { described_class }

  let(:current_month) { 10 }
  let(:current_year) { 2025 }
  let(:last_month) { current_month - 1 }

  let(:operation_object) { double("operation", wait_until_done!: true, error?: false) }
  let(:response_object) { double("response", name: "name") }
  let(:sample_query_set_service_stub) { double("sample_query_set_service", create_sample_query_set: response_object) }
  let(:sample_query_service_stub) { double("sample_query_service", import_sample_queries: operation_object) }

  before do
    travel_to Time.zone.local(current_year.to_s, current_month.to_s, 25)
    allow(DiscoveryEngine::Clients).to receive_messages(sample_query_set_service: sample_query_set_service_stub, sample_query_service: sample_query_service_stub)
  end

  after { travel_back }

  describe ".create" do
    it "calls the create sample query set endpoint" do
      sample_query_set.create

      expect(sample_query_set_service_stub).to have_received(:create_sample_query_set).with(
        sample_query_set: {
          display_name: "Clickstream #{current_year}-#{last_month}",
          description: "Generated from #{current_year}-#{last_month} BigQuery clickstream data",
        },
        sample_query_set_id: "clickstream_#{current_year}-#{last_month}",
        parent: Rails.application.config.discovery_engine_default_location_name,
      )
    end
  end

  describe "#import_from_bigquery" do
    let(:bigquery_source) do
      {
        dataset_id: described_class::BIGQUERY_DATASET_ID,
        table_id: described_class::BIGQUERY_TABLE_ID,
        project_id: Rails.application.config.google_cloud_project_id,
        partition_date: {
          year: current_year,
          month: last_month,
          day: 1,
        },
      }
    end

    it "calls the import_sample_queries endpoint on the sample query service client" do
      sqs = sample_query_set.create
      sqs.import_from_bigquery

      expect(sample_query_service_stub).to have_received(:import_sample_queries).with(
        parent: sqs.set.name,
        bigquery_source: bigquery_source,
      )
    end

    context "when operation does not complete" do
      let(:error_stub) { double("error", message: "An error message") }
      let(:operation_object) { double("operation", wait_until_done!: true, error?: true, error: error_stub) }

      it "raises an error" do
        sqs = sample_query_set.create

        expect { sqs.import_from_bigquery }.to raise_error("An error message")
      end
    end
  end
end
