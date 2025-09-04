RSpec.describe DiscoveryEngine::Quality::GcpBucketExporter do
  subject(:gcp_bucket_exporter) { described_class.new }

  let(:google_cloud_storage_client) { double("google_cloud_storage_client") }
  let(:storage) { double("storage") }
  let(:gcp_bucket) { double("gcp_bucket") }
  let(:data) { { "key" => "value" }.to_json }

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
      .with("data", "filename")

    allow(StringIO)
      .to receive(:new)
      .with(data)
      .and_return("data")
  end

  describe "#send" do
    it "accesses a storage bucket in gcp" do
      gcp_bucket_exporter.send(data)

      expect(gcp_bucket)
        .to have_received(:create_file)
        .with("data", "filename")
    end
  end
end
