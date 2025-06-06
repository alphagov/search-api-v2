RSpec.describe DiscoveryEngine::Evaluation::SampleQuerySetManager do
  subject(:manager) do
    described_class.new(
      project_id: project_id,
      sample_query_set_client: sample_query_set_client,
      sample_query_client: sample_query_client,
    )
  end

  let(:project_id) { "test-project" }
  let(:sample_query_set_client) { instance_double(Google::Cloud::DiscoveryEngine::V1beta::SampleQuerySetService::Client) }
  let(:sample_query_client) { instance_double(Google::Cloud::DiscoveryEngine::V1beta::SampleQueryService::Client) }
  let(:location) { "projects/test-project/locations/global" }

  describe "#create_and_import" do
    let(:date) { Date.new(2025, 4, 15) }
    let(:sample_query_set) { double("sample_query_set", name: "#{location}/sampleQuerySets/clickstream_2025-04") }
    let(:import_operation) { double("operation", wait_until_done!: nil, error?: false) }

    before do
      allow(sample_query_set_client).to receive(:create_sample_query_set).and_return(sample_query_set)
      allow(sample_query_client).to receive(:import_sample_queries).and_return(import_operation)
    end

    it "creates a sample query set with correct parameters" do
      manager.create_and_import(date: date)

      expect(sample_query_set_client).to have_received(:create_sample_query_set).with(
        sample_query_set: {
          display_name: "Clickstream Apr 2025",
          description: "Generated from Apr 2025 BigQuery clickstream data",
        },
        sample_query_set_id: "clickstream_2025-04",
        parent: location,
      )
    end

    it "imports from BigQuery with correct parameters" do
      manager.create_and_import(date: date)

      expect(sample_query_client).to have_received(:import_sample_queries).with(
        parent: sample_query_set.name,
        bigquery_source: {
          dataset_id: "automated_evaluation_input",
          table_id: "clickstream",
          project_id: project_id,
          partition_date: {
            year: 2025,
            month: 4,
            day: 1,
          },
        },
      )
    end

    it "waits for import operation to complete" do
      manager.create_and_import(date: date)

      expect(import_operation).to have_received(:wait_until_done!)
    end

    it "returns the created sample query set" do
      result = manager.create_and_import(date: date)

      expect(result).to eq(sample_query_set)
    end

    context "when import operation fails" do
      let(:error_message) { "Something went wrong" }
      let(:import_operation) do
        double("operation", wait_until_done!: nil, error?: true, error: double(message: error_message))
      end

      it "raises an error with the operation error message" do
        expect { manager.create_and_import(date: date) }.to raise_error(StandardError, "Error importing sample queries: #{error_message}")
      end
    end

    context "when no date is provided" do
      around do |example|
        Timecop.freeze(Date.new(2025, 5, 15)) do
          example.run
        end
      end

      it "defaults to previous month" do
        manager.create_and_import

        expect(sample_query_set_client).to have_received(:create_sample_query_set).with(
          hash_including(
            sample_query_set_id: "clickstream_2025-04",
            sample_query_set: hash_including(
              display_name: "Clickstream Apr 2025",
            ),
          ),
        )
      end
    end
  end

  describe "#delete" do
    let(:sample_query_set_id) { "clickstream_2025-04" }

    before do
      allow(sample_query_set_client).to receive(:delete_sample_query_set)
    end

    it "deletes the sample query set" do
      manager.delete(sample_query_set_id)

      expect(sample_query_set_client).to have_received(:delete_sample_query_set).with(
        name: "#{location}/sampleQuerySets/#{sample_query_set_id}",
      )
    end
  end

  describe "#list_all" do
    let(:sample_query_sets) { double("sample_query_sets") }

    before do
      allow(sample_query_set_client).to receive(:list_sample_query_sets).and_return(sample_query_sets)
    end

    it "lists all sample query sets" do
      result = manager.list_all

      expect(sample_query_set_client).to have_received(:list_sample_query_sets).with(parent: location)
      expect(result).to eq(sample_query_sets)
    end
  end

  describe "#list_sample_queries" do
    let(:sample_query_set_name) { "#{location}/sampleQuerySets/clickstream_2025-04" }
    let(:sample_queries) { double("sample_queries") }
    let(:limited_queries) { double("limited_queries") }

    before do
      allow(sample_query_client).to receive(:list_sample_queries).and_return(sample_queries)
      allow(sample_queries).to receive(:first).with(5).and_return(limited_queries)
    end

    it "lists sample queries with default limit" do
      result = manager.list_sample_queries(sample_query_set_name)

      expect(sample_query_client).to have_received(:list_sample_queries).with(parent: sample_query_set_name)
      expect(sample_queries).to have_received(:first).with(5)
      expect(result).to eq(limited_queries)
    end

    it "lists sample queries with custom limit" do
      allow(sample_queries).to receive(:first).with(10).and_return(limited_queries)

      result = manager.list_sample_queries(sample_query_set_name, limit: 10)

      expect(sample_queries).to have_received(:first).with(10)
      expect(result).to eq(limited_queries)
    end
  end
end
