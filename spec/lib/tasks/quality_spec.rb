RSpec.describe "Quality tasks" do
  let(:sample_query_set) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }
  let(:sample_query_sets) { instance_double(DiscoveryEngine::Quality::SampleQuerySets) }

  describe "setup_sample_query_sets" do
    before do
      Rake::Task["quality:setup_sample_query_sets"].reenable

      allow(DiscoveryEngine::Quality::SampleQuerySets)
      .to receive(:new)
      .with(:last_month)
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
    before do
      Rake::Task["quality:setup_sample_query_set"].reenable

      allow(DiscoveryEngine::Quality::SampleQuerySet)
      .to receive(:new)
      .with(month: 1, year: 2025, table_id: "clickstream")
      .and_return(sample_query_set)
    end

    it "creates and imports a sample set" do
      expect(sample_query_set)
        .to receive(:create_and_import)
        .once
      Rake::Task["quality:setup_sample_query_set"].invoke("2025", "1", "clickstream")
    end

    it "raises an error unless table_id is provided" do
      message = "table id is a required argument"
      expect {
        Rake::Task["quality:setup_sample_query_set"].invoke("2025", "1")
      }.to raise_error(message)
    end

    it "raises an error unless year and month are provided" do
      message = "year and month are required arguments"
      expect {
        Rake::Task["quality:setup_sample_query_set"].invoke("clickstream")
      }.to raise_error(message)
    end

    it "raises an error if year and month are not provided in YYYY MM order" do
      message = "arguments must be provided in YYYY MM order"
      expect {
        Rake::Task["quality:setup_sample_query_set"].invoke("05", "2025", "clickstream")
      }.to raise_error(message)
    end
  end

  describe "report_quality_metrics" do
    let(:evaluations) { instance_double(DiscoveryEngine::Quality::Evaluations) }
    let(:evaluation_response) { double }
    let(:registry) { double("registry", gauge: nil) }
    let(:push_client) { double("push_client", add: nil) }
    let(:metric_collector) { instance_double(Metrics::Evaluation) }

    before do
      Rake::Task["quality:report_quality_metrics"].reenable

      allow(DiscoveryEngine::Quality::Evaluations)
        .to receive(:new)
        .with(metric_collector)
        .and_return(evaluations)

      allow(Prometheus::Client)
        .to receive(:registry)
        .and_return(registry)

      allow(Prometheus::Client::Push)
        .to receive(:new)
        .and_return(push_client)

      allow(Metrics::Evaluation)
        .to receive(:new)
        .with(registry)
        .and_return(metric_collector)
    end

    it "reports quality metrics to prometheus" do
      ClimateControl.modify PROMETHEUS_PUSHGATEWAY_URL: "https://www.something.example.org" do
        expect(evaluations)
          .to receive(:collect_all_quality_metrics)
          .once
        Rake::Task["quality:report_quality_metrics"].invoke
      end
    end
  end
end
