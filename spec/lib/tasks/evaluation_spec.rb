RSpec.describe "Evaluation tasks" do
  describe "setup_sample_query_sets" do
    let(:sample_query_set) { instance_double(DiscoveryEngine::Evaluation::SampleQuerySet) }

    before do
      Rake::Task["evaluation:setup_sample_query_sets"].reenable

      allow(DiscoveryEngine::Evaluation::SampleQuerySet)
      .to receive(:new)
      .and_return(sample_query_set)
    end

    it "creates and imports a sample set" do
      expect(sample_query_set)
        .to receive(:create_and_import)
        .once
      Rake::Task["evaluation:setup_sample_query_sets"].invoke
    end
  end

  describe "fetch_evaluations" do
    let(:evaluation_runner) { instance_double(DiscoveryEngine::Evaluation::EvaluationRunner) }
    let(:registry) { double("registry", gauge: nil) }
    let(:push_client) { double("push_client", add: nil) }
    let(:metric_evaluation) { instance_double(Metrics::Evaluation) }

    before do
      Rake::Task["evaluation:fetch_evaluations"].reenable

      allow(DiscoveryEngine::Evaluation::EvaluationRunner)
        .to receive(:new)
        .with("clickstream_01_07")
        .and_return(evaluation_runner)

      allow(Prometheus::Client)
        .to receive(:registry)
        .and_return(registry)

      allow(Prometheus::Client::Push)
        .to receive(:new)
        .and_return(push_client)

      allow(Metrics::Evaluation)
        .to receive(:new)
        .with(registry)
        .and_return(metric_evaluation)
    end

    it "creates and outputs evaluations" do
      ClimateControl.modify PROMETHEUS_PUSHGATEWAY_URL: "https://www.something.example.org" do
        expect(evaluation_runner)
          .to receive(:fetch_quality_metrics)
          .once

        expect(metric_evaluation)
          .to receive(:record_evaluations)
          .once
        Rake::Task["evaluation:fetch_evaluations"].invoke("clickstream_01_07")
      end
    end

    context "when sample_id is not passed in" do
      it "raises and error" do
        expect { Rake::Task["evaluation:fetch_evaluations"].invoke }
          .to raise_error("sample_set_id is required")
      end
    end
  end
end
