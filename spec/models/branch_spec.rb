RSpec.describe Branch do
  subject(:branch) { described_class.new("my-branch") }

  describe ".default" do
    it "returns the default branch" do
      expect(described_class.default).to eq(described_class.new("default_branch"))
    end
  end

  describe "#name" do
    it "returns the fully qualified name of the branch" do
      expect(branch.name).to eq("[location]/collections/default_collection/dataStores/govuk_content/branches/my-branch")
    end
  end
end
