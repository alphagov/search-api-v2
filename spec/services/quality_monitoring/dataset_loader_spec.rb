RSpec.describe QualityMonitoring::DatasetLoader do
  subject(:csv_loader) { described_class.new(path) }

  let(:path) { file_fixture("quality_monitoring_datasets/example.csv") }

  describe "#data" do
    it "returns a hash of queries and links based on the CSV data grouped by query" do
      expect(csv_loader.data).to eq(
        "i want to fish" => ["/i-want-to-fish", "/i-really-want-to-fish"],
        "external" => ["https://www.example.org"],
      )
    end
  end
end
