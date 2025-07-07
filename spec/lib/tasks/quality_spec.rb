RSpec.describe "Quality tasks" do
  describe "setup_sample_query_sets" do
    let(:sample_query_set) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }

    before do
      Rake::Task["quality:setup_sample_query_sets"].reenable

      allow(DiscoveryEngine::Quality::SampleQuerySet)
      .to receive(:new)
      .and_return(sample_query_set)
    end

    it "creates and imports a sample set" do
      expect(sample_query_set)
        .to receive(:create_and_import)
        .once
      Rake::Task["quality:setup_sample_query_sets"].invoke
    end
  end

  describe "setup_sample_query_set" do
    let(:sample_query_set) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }
    let(:sample_query_sets) { instance_double(DiscoveryEngine::Quality::SampleQuerySets, sets: [sample_query_set]) }
    let(:expected_month_interval) { DiscoveryEngine::Quality::MonthInterval.new(2025, 1) }

    before do
      Rake::Task["quality:setup_sample_query_set"].reenable

      allow(DiscoveryEngine::Quality::SampleQuerySets)
        .to receive(:new)
        .with(expected_month_interval)
        .and_return(sample_query_sets)
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
    let(:response_object) { double("response", name: "/sample_query_set/1") }
    let(:sample_query_set_service_stub) { double("sample_query_set_service", create_sample_query_set: response_object) }
    let(:operation_object) { double("operation", wait_until_done!: true, error?: false) }
    let(:sample_query_service_stub) { double("sample_query_service", import_sample_queries: operation_object) }

    before do
      Rake::Task["quality:report_quality_metrics"].reenable

      allow(DiscoveryEngine::Quality::Evaluation)
        .to receive(:new)
        .with("clickstream_2025-10")
        .and_return(evaluation)

      allow(DiscoveryEngine::Quality::Evaluation)
        .to receive(:new)
        .with("clickstream_2025-09")
        .and_return(evaluation)

      allow(DiscoveryEngine::Clients).to receive_messages(sample_query_set_service: sample_query_set_service_stub, sample_query_service: sample_query_service_stub)

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
