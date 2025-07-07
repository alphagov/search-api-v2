RSpec.describe DiscoveryEngine::Quality::SampleQuerySets do
  subject(:sample_query_sets) { described_class.new(month_interval) }

  let(:month_interval) { DiscoveryEngine::Quality::MonthInterval.new(2025, 1) }

  describe "#all" do
    it "returns SampleQuerySet objects" do
      expect(sample_query_sets.all.count).to eq(1)
    end

    it "creates a SampleQuerySet object for each table name" do
      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .with(month_interval, "clickstream")

      sample_query_sets.all
    end
  end
end
