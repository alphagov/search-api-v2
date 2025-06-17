RSpec.describe DataStore do
  subject(:data_store) { described_class.new("my-data-store") }

  describe ".default" do
    it "returns the default data store" do
      expect(described_class.default).to eq(described_class.new("govuk_content"))
    end
  end

  describe "#name" do
    it "returns the fully qualified name of the data store" do
      expect(data_store.name).to eq("[location]/collections/default_collection/dataStores/my-data-store")
    end
  end
end
