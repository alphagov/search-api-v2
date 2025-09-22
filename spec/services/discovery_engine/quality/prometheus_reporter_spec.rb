RSpec.describe DiscoveryEngine::Quality::PrometheusReporter do
  subject(:prometheus_reporter) { described_class.new }

  let(:month_label) { :last_month }
  let(:table_id) { "explicit" }
  let(:quality_metrics) { "quality_metrics" }
  let(:registry) { double("registry", gauge: nil) }
  let(:push_client) { double("push_client", add: nil) }
  let(:metric_collector) { instance_double(Metrics::Evaluation) }

  before do
    allow(Prometheus::Client::Push)
      .to receive(:new)
      .and_return(push_client)

    allow(Metrics::Evaluation)
      .to receive(:instance)
      .and_return(metric_collector)

    allow(metric_collector)
      .to receive(:record_evaluations)
      .with(anything, anything, anything)

    allow(metric_collector)
      .to receive(:registry)
      .and_return(registry)
  end

  describe "send" do
    it "adds metrics to the Prometheus registry and pushes to the Prometheus client" do
      ClimateControl.modify PROMETHEUS_PUSHGATEWAY_URL: "https://www.something.example.org" do
        prometheus_reporter.send(quality_metrics, month_label, table_id)

        expect(metric_collector)
          .to have_received(:record_evaluations)
          .with(quality_metrics, :last_month, "explicit")

        expect(push_client)
          .to have_received(:add)
          .with(registry)
      end
    end

    context "when push gateway returns an error code" do
      let(:erroring_push_client) { double("erroring_push_client") }
      let(:logger_message) { "Failed to push evaluations to Prometheus push gateway: 'Prometheus::Client::Push::HttpError'" }

      before do
        allow(Prometheus::Client::Push)
          .to receive(:new)
          .and_return(erroring_push_client)

        allow(erroring_push_client)
          .to receive(:add)
          .and_raise(Prometheus::Client::Push::HttpError)
      end

      it "logs and raises an error" do
        ClimateControl.modify PROMETHEUS_PUSHGATEWAY_URL: "https://www.something.example.org" do
          expect {
            prometheus_reporter.send(quality_metrics, month_label, table_id)
          }.to raise_error(Prometheus::Client::Push::HttpError)
        end
      end
    end
  end
end
