RSpec.describe DiscoveryEngine::Quality::SampleQuerySets do
  subject(:sample_query_sets) { described_class.new(month_interval) }
  let(:sample_query_set) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }
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

  describe "#create_and_import_all" do
    it "calls create_and_import on each SampleQuerySet" do
      allow(DiscoveryEngine::Quality::SampleQuerySet)
      .to receive(:new)
      .and_return(sample_query_set)

      expect([sample_query_set]).to all(receive(:create_and_import))

      sample_query_sets.create_and_import_all
    end
  end
end
