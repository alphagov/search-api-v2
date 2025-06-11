RSpec.describe "Evaluation tasks" do
  describe "evaluation:clickstream:setup_sample_set" do
    let(:sample_query_set) { instance_double(DiscoveryEngine::Evaluation::SampleQuerySet) }

    before do
      Rake::Task["evaluation:clickstream:setup_sample_set"].reenable
    end

    it "creates and imports a sample set" do
      expect(DiscoveryEngine::Evaluation::SampleQuerySet)
        .to receive(:create)
        .once
        .and_return(sample_query_set)

      expect(sample_query_set)
        .to receive(:import_from_bigquery)

      Rake::Task["evaluation:clickstream:setup_sample_set"].invoke
    end

    it "allows a table_id to be passed in" do
      expect(DiscoveryEngine::Evaluation::SampleQuerySet)
        .to receive(:create)
        .with(table_id: "explicit")
        .once
        .and_return(sample_query_set)

      expect(sample_query_set)
        .to receive(:import_from_bigquery)

      Rake::Task["evaluation:clickstream:setup_sample_set"].invoke("explicit")
    end
  end
end
