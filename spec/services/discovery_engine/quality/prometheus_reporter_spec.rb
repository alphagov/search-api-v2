RSpec.describe DiscoveryEngine::Quality::PrometheusReporter do
  subject(:prometheus_reporter) { described_class.new }

  let(:month_label) { :last_month }
  let(:table_id) { "explicit" }
  let(:quality_metrics) { "quality_metrics" }
  let(:registry) { double("registry", gauge: nil) }
  let(:metric_collector) { instance_double(Metrics::Evaluation) }

  before do
    allow(Prometheus::Client)
      .to receive(:registry)
      .and_return(registry)

    allow(Metrics::Evaluation)
      .to receive(:new)
      .with(registry)
      .and_return(metric_collector)

    allow(metric_collector)
      .to receive(:record_evaluations)
      .with(anything, anything, anything)
  end

  describe "send" do
    it "adds metrics to the Prometheus registry" do
      prometheus_reporter.send(quality_metrics, month_label, table_id)

      expect(metric_collector)
        .to have_received(:record_evaluations)
        .with("quality_metrics", :last_month, "explicit")
    end
  end
end
