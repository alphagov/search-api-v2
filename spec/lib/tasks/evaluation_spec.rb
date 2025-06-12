RSpec.describe "Evaluation tasks" do
  describe "evaluation:clickstream:setup_sample_set" do
    let(:sample_query_set) { instance_double(DiscoveryEngine::Evaluation::SampleQuerySet) }

    before do
      Rake::Task["evaluation:clickstream:setup_sample_set"].reenable
      allow(DiscoveryEngine::Evaluation::SampleQuerySet)
      .to receive(:new)
      .and_return(sample_query_set)
    end

    it "creates and imports a sample set" do
      expect(sample_query_set)
        .to receive(:create_and_import)
        .once
      Rake::Task["evaluation:clickstream:setup_sample_set"].invoke
    end
  end
end
