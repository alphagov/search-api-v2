RSpec.describe "Quality tasks" do
  let(:sample_query_set) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }
  let(:sample_query_sets) { instance_double(DiscoveryEngine::Quality::SampleQuerySets) }

  describe "setup_sample_query_sets" do
    around do |example|
      Timecop.freeze(2025, 11, 1) { example.call }
    end

    let(:expected_month_interval) { DiscoveryEngine::Quality::MonthInterval.new(2025, 10) }

    before do
      Rake::Task["quality:setup_sample_query_sets"].reenable

      allow(DiscoveryEngine::Quality::SampleQuerySets)
      .to receive(:new)
      .with(expected_month_interval)
      .and_return(sample_query_sets)

      allow(sample_query_sets)
      .to receive(:create_and_import_all)
    end

    it "creates and imports a sample set" do
      expect(sample_query_sets)
        .to receive(:create_and_import_all)
        .once
      Rake::Task["quality:setup_sample_query_sets"].invoke
    end
  end

  describe "setup_sample_query_set" do
    let(:expected_month_interval) { DiscoveryEngine::Quality::MonthInterval.new(2025, 1) }

    before do
      Rake::Task["quality:setup_sample_query_set"].reenable

      allow(DiscoveryEngine::Quality::SampleQuerySet)
      .to receive(:new)
      .with(expected_month_interval, "clickstream")
      .and_return(sample_query_set)
    end

    it "creates and imports a sample set" do
      expect(sample_query_set)
        .to receive(:create_and_import)
        .once
      Rake::Task["quality:setup_sample_query_set"].invoke("2025", "1")
    end
  end

  describe "report_quality_metrics" do
    around do |example|
      Timecop.freeze(2025, 11, 1) { example.call }
    end

    let(:evaluation) { instance_double(DiscoveryEngine::Quality::Evaluation, fetch_quality_metrics: evaluation_response) }
    let(:evaluation_response) { double }
    let(:registry) { double("registry", gauge: nil) }
    let(:push_client) { double("push_client", add: nil) }
    let(:metric_evaluation) { instance_double(Metrics::Evaluation) }
    let(:sample_query_set) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }
    let(:sample_query_set_month_before_last) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }
    let(:expected_month_interval) { DiscoveryEngine::Quality::MonthInterval.new(2025, 10) }
    let(:expected_month_before_last_interval) { DiscoveryEngine::Quality::MonthInterval.new(2025, 9) }

    before do
      Rake::Task["quality:report_quality_metrics"].reenable

      allow(DiscoveryEngine::Quality::SampleQuerySets)
      .to receive(:new)
      .with(expected_month_interval)
      .and_return(sample_query_sets)

      allow(DiscoveryEngine::Quality::SampleQuerySets)
      .to receive(:new)
      .with(expected_month_before_last_interval)
      .and_return(sample_query_sets)

      allow(sample_query_sets)
      .to receive(:all)
      .and_return([sample_query_set])

      allow(DiscoveryEngine::Quality::Evaluation)
        .to receive(:new)
        .with(sample_query_set)
        .and_return(evaluation)

      allow(DiscoveryEngine::Quality::Evaluation)
        .to receive(:new)
        .with(sample_query_set_month_before_last)
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

    it "reports quality metrics to prometheus" do
      ClimateControl.modify PROMETHEUS_PUSHGATEWAY_URL: "https://www.something.example.org" do
        expect(evaluation)
          .to receive(:fetch_quality_metrics)
          .twice

        expect(metric_evaluation)
          .to receive(:record_evaluations)
          .once
          .with(evaluation_response, :last_month)

        expect(metric_evaluation)
        .to receive(:record_evaluations)
        .once
        .with(evaluation_response, :month_before_last)

        Rake::Task["quality:report_quality_metrics"].invoke
      end
    end
  end
end
