RSpec.describe "Evaluation tasks" do
  describe "setup_sample_set" do
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

  describe "fetch_evaluations" do
    let(:evaluation_resource) { instance_double(DiscoveryEngine::Evaluation::EvaluationRunner) }

    before do
      Rake::Task["evaluation:clickstream:fetch_evaluations"].reenable

      allow(DiscoveryEngine::Evaluation::EvaluationRunner)
        .to receive(:new)
        .with("clickstream_01_07")
        .and_return(evaluation_resource)
    end

    it "creates and outputs evaluations" do
      expect(evaluation_resource)
        .to receive(:fetch_quality_metrics)
        .once
      Rake::Task["evaluation:clickstream:fetch_evaluations"].invoke("clickstream_01_07")
    end

    context "when sample_id is not passed in" do
      it "raises and error" do
        expect { Rake::Task["evaluation:clickstream:fetch_evaluations"].invoke }
          .to raise_error("sample_set_id is required")
      end
    end
  end
end
