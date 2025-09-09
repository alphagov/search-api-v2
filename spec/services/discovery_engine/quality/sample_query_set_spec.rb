RSpec.describe DiscoveryEngine::Quality::SampleQuerySet do
  around do |example|
    Timecop.freeze(2025, 11, 1) { example.call }
  end

  before do
    allow(DiscoveryEngine::Clients).to receive_messages(sample_query_set_service: sample_query_set_service_stub, sample_query_service: sample_query_service_stub)
  end

  let(:sample_query_set_service_stub) { double("sample_query_set_service", create_sample_query_set: nil) }
  let(:sample_query_service_stub) { double("sample_query_service", import_sample_queries: operation_object) }
  let(:operation_object) { double("operation", wait_until_done!: true, error?: false) }
  let(:table_id) { "clickstream" }
  let(:month_label) { :last_month }

  describe "#create_and_import_queries" do
    context "when the month label ':last_month' is provided" do
      subject(:sample_query_set) { described_class.new(month_label:, table_id:) }

      it "creates a sample query set for last month" do
        sample_query_set.create_and_import_queries

        expect(sample_query_set_service_stub).to have_received(:create_sample_query_set).with(
          sample_query_set: {
            display_name: "clickstream 2025-10",
            description: "Generated from 2025-10 BigQuery clickstream data",
          },
          sample_query_set_id: "clickstream_2025-10",
          parent: Rails.application.config.discovery_engine_default_location_name,
        )

        expect(sample_query_service_stub).to have_received(:import_sample_queries).with(
          parent: "[location]/sampleQuerySets/clickstream_2025-10",
          bigquery_source: {
            dataset_id: "automated_evaluation_input",
            table_id: "clickstream",
            project_id: Rails.application.config.google_cloud_project_id,
            partition_date: {
              year: 2025,
              month: 10,
              day: 1,
            },
          },
        )
      end

      context "when operation does not complete" do
        let(:error_stub) { double("error", message: "An error message") }
        let(:operation_object) { double("operation", wait_until_done!: true, error?: true, error: error_stub) }

        it "raises an error" do
          expect { sample_query_set.create_and_import_queries }.to raise_error("An error message")
        end
      end

      context "when sample query set already exists" do
        let(:erroring_service) { double("sample_query_set") }

        before do
          allow(DiscoveryEngine::Clients).to receive(:sample_query_set_service).and_return(erroring_service)

          allow(erroring_service)
            .to receive(:create_sample_query_set)
            .with(anything)
            .and_raise(Google::Cloud::AlreadyExistsError)

          allow(Rails.logger).to receive(:warn)
        end

        it "handles the error and logs a warning" do
          sample_query_set.create_and_import_queries
          expect(erroring_service).to have_received(:create_sample_query_set).exactly(1).times
          expect(Rails.logger).to have_received(:warn)
            .with("SampleQuerySet clickstream 2025-10 already exists. Skipping query set creation...")
        end
      end
    end

    context "when a year and month are provided" do
      subject(:sample_query_set) { described_class.new(month:, year:, table_id:) }

      let(:year) { 2025 }
      let(:month) { 9 }

      it "creates a sample query set for the year and month provided" do
        sample_query_set.create_and_import_queries

        expect(sample_query_set_service_stub).to have_received(:create_sample_query_set).with(
          sample_query_set: {
            display_name: "clickstream 2025-09",
            description: "Generated from 2025-09 BigQuery clickstream data",
          },
          sample_query_set_id: "clickstream_2025-09",
          parent: Rails.application.config.discovery_engine_default_location_name,
        )

        expect(sample_query_service_stub).to have_received(:import_sample_queries).with(
          parent: "[location]/sampleQuerySets/clickstream_2025-09",
          bigquery_source: {
            dataset_id: "automated_evaluation_input",
            table_id: "clickstream",
            project_id: Rails.application.config.google_cloud_project_id,
            partition_date: {
              year: 2025,
              month: 9,
              day: 1,
            },
          },
        )
      end
    end
  end

  describe "#name" do
    subject(:sample_query_set) { described_class.new(month_label:, table_id:) }

    it "returns the fully qualified GCP name of the sample query set" do
      expect(sample_query_set.name).to eq("[location]/sampleQuerySets/clickstream_2025-10")
    end
  end

  describe "#display_name" do
    subject(:sample_query_set) { described_class.new(month_label:, table_id:) }

    it "returns the display name of the sample query set" do
      expect(sample_query_set.display_name).to eq("clickstream 2025-10")
    end
  end

  describe "#partition_date" do
    subject(:sample_query_set) { described_class.new(month_label:, table_id:) }

    let(:partition_date) { instance_double(DiscoveryEngine::Quality::PartitionDate) }

    before do
      allow(DiscoveryEngine::Quality::PartitionDate)
        .to receive(:new)
        .with(month_label:, month: nil, year: nil)
        .and_return(partition_date)

      allow(partition_date).to receive(:calculate)
    end

    it "fetches the date from the PartitionDate class" do
      sample_query_set.partition_date

      expect(partition_date).to have_received(:calculate)
    end
  end
end
