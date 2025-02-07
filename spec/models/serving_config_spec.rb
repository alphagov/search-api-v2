RSpec.describe ServingConfig do
  subject(:serving_config) { described_class.new("my-serving-config") }

  describe ".default" do
    it "returns the default serving config" do
      expect(described_class.default).to eq(described_class.new("default_search"))
    end
  end

  describe "#name" do
    it "returns the fully qualified name of the serving config" do
      expect(serving_config.name).to eq("[collection]/engines/govuk/servingConfigs/my-serving-config")
    end
  end
end
