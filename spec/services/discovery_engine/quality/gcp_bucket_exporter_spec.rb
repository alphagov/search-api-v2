RSpec.describe DiscoveryEngine::Quality::GcpBucketExporter do
  subject(:gcp_bucket_exporter) { described_class.new }

  let(:time_stamp) { "2025-06-01 12:30:00" }
  let(:partition_date) { Date.new(2025, 3, 1) }
  let(:table_id) { "explicit" }

  describe "file_name" do
    it "returns a filename that contains the required folder names" do
      file_name = gcp_bucket_exporter.file_name(time_stamp, table_id, partition_date)
      expected_filename =
        "judgement_list=explicit/partition_date=2025-03-01/create_time=2025-06-01 12:30:00/results.json"
      expect(file_name).to eq(expected_filename)
    end
  end

  describe "#send" do
    let(:google_cloud_storage_client) { double("google_cloud_storage_client") }
    let(:storage) { double("storage") }
    let(:gcp_bucket) { double("gcp_bucket") }
    let(:data) { { "key" => "value" }.to_json }
    let(:file_name) { "judgement_list=explicit/partition_date=2025-03-01/create_time=2025-06-01 12:30:00/results.json" }

    before do
      allow(DiscoveryEngine::Clients)
          .to receive(:cloud_storage_service)
          .and_return(google_cloud_storage_client)

      allow(google_cloud_storage_client)
        .to receive(:new)
        .with(project: "search-api-v2-integration")
        .and_return(storage)

      allow(storage)
        .to receive(:bucket)
        .with("search-api-v2-integration_vais_evaluation_output")
        .and_return(gcp_bucket)

      allow(gcp_bucket)
        .to receive(:create_file)
      .with("data", file_name)

      allow(StringIO)
        .to receive(:new)
        .with(data)
        .and_return("data")
    end

    it "accesses a storage bucket in gcp" do
      gcp_bucket_exporter.send(time_stamp, table_id, partition_date, data)

      expect(gcp_bucket)
        .to have_received(:create_file)
        .with("data", file_name)
    end
  end
end
