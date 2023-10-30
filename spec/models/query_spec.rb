RSpec.describe Query, type: :model do
  subject(:query) { described_class.new }

  describe "#result_set" do
    subject(:result_set) { query.result_set }

    it "returns an empty result set" do
      expect(result_set.results).to be_empty
      expect(result_set.total).to be_zero
      expect(result_set.start).to be_zero
    end
  end
end
