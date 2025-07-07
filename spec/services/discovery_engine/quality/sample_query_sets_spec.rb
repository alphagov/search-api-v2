RSpec.describe DiscoveryEngine::Quality::SampleQuerySets do
  subject(:sample_query_sets) { described_class.new(month_interval) }

  let(:month_interval) { DiscoveryEngine::Quality::MonthInterval.new(2025, 1) }

  describe "sets" do
    it "returns SampleQuerySet objects" do
      expect(sample_query_sets.sets.count).to eq(3)
    end

    it "creates a SampleQuerySet object for each table name" do
      table_ids = described_class::BIGQUERY_TABLE_IDS
      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .exactly(3).times
        .with(month_interval, table_ids.first)

      sample_query_sets.sets
    end
  end
end
