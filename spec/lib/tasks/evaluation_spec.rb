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
    around do |example|
      Timecop.freeze(2025, 11, 1) { example.call }
    end

    let(:evaluation) { instance_double(DiscoveryEngine::Quality::Evaluation) }
    let(:registry) { double("registry", gauge: nil) }
    let(:push_client) { double("push_client", add: nil) }
    let(:metric_evaluation) { instance_double(Metrics::Evaluation) }

    before do
      Rake::Task["evaluation:report_quality_metrics"].reenable

      allow(DiscoveryEngine::Quality::Evaluation)
        .to receive(:new)
        .with("clickstream_2025-10")
        .and_return(evaluation)

      allow(DiscoveryEngine::Quality::Evaluation)
        .to receive(:new)
        .with("clickstream_2025-09")
        .and_return(evaluation)

      allow(Prometheus::Client)
        .to receive(:registry)
        .and_return(registry)

      allow(Prometheus::Client::Push)
        .to receive(:new)
        .and_return(push_client)

      allow(Metrics::Evaluation)
        .to receive(:new)
        .with(registry, :last_month)
        .and_return(metric_evaluation)

      allow(Metrics::Evaluation)
        .to receive(:new)
        .with(registry, :month_before_last)
        .and_return(metric_evaluation)
    end

    it "reports quality metrics to prometheus" do
      ClimateControl.modify PROMETHEUS_PUSHGATEWAY_URL: "https://www.something.example.org" do
        expect(evaluation)
          .to receive(:fetch_quality_metrics)
          .twice

        expect(metric_evaluation)
          .to receive(:record_evaluations)
          .twice
        Rake::Task["evaluation:report_quality_metrics"].invoke
      end
    end
  end
end
