RSpec.describe DiscoveryEngine::Quality::SampleQuerySets do
  subject(:sample_query_sets) { described_class.new(:last_month) }

  let(:sample_query_set) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }
  let(:month_label) { :last_month }

  describe "#all" do
    it "returns SampleQuerySet objects" do
      expect(sample_query_sets.all.count).to eq(3)
    end

    it "creates a SampleQuerySet object for each table name" do
      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .with(table_id: "clickstream", month_label:)

      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .with(table_id: "binary", month_label:)

      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .with(table_id: "explicit", month_label:)

      sample_query_sets.all
    end
  end

  describe "#create_and_import_all" do
    let(:sample_query_set_clickstream) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }
    let(:sample_query_set_binary) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }
    let(:sample_query_set_explicit) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }

    it "calls create_and_import_queries on each SampleQuerySet instance" do
      allow(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .with(table_id: "clickstream", month_label: month_label)
        .and_return(sample_query_set_clickstream)

      allow(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .with(table_id: "binary", month_label: month_label)
        .and_return(sample_query_set_binary)

      allow(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .with(table_id: "explicit", month_label: month_label)
        .and_return(sample_query_set_explicit)

      expect(sample_query_set_clickstream).to receive(:create_and_import_queries)
      expect(sample_query_set_binary).to receive(:create_and_import_queries)
      expect(sample_query_set_explicit).to receive(:create_and_import_queries)

      sample_query_sets.create_and_import_all
    end
  end
end
