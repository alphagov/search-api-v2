RSpec.describe "Evaluation tasks" do
  describe "setup_sample_query_sets" do
    let(:sample_query_set) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }

    before do
      Rake::Task["evaluation:setup_sample_query_sets"].reenable

      allow(DiscoveryEngine::Quality::SampleQuerySet)
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

  describe "report_quality_metrics" do
    let(:evaluation) { instance_double(DiscoveryEngine::Quality::Evaluation) }
    let(:registry) { double("registry", gauge: nil) }
    let(:push_client) { double("push_client", add: nil) }
    let(:metric_evaluation) { instance_double(Metrics::Evaluation) }

    before do
      Rake::Task["evaluation:report_quality_metrics"].reenable

      allow(DiscoveryEngine::Quality::Evaluation)
        .to receive(:new)
        .with("clickstream_01_07")
        .and_return(evaluation)

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
        expect(evaluation)
          .to receive(:fetch_quality_metrics)
          .once

        expect(metric_evaluation)
          .to receive(:record_evaluations)
          .once
        Rake::Task["evaluation:report_quality_metrics"].invoke("clickstream_01_07")
      end
    end

    context "when sample_id is not passed in" do
      it "raises and error" do
        expect { Rake::Task["evaluation:report_quality_metrics"].invoke }
          .to raise_error("sample_set_id is required")
      end
    end
  end
end
