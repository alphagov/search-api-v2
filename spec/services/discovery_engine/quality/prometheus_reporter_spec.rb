RSpec.describe DiscoveryEngine::Quality::PrometheusReporter do
  subject(:prometheus_reporter) { described_class.new }

  let(:evaluation) { double("evaluation") }
  let(:quality_metrics) { "quality_metrics" }

  describe "send" do
    it "is to be implemented" do
      expect(prometheus_reporter.send(quality_metrics, evaluation)).to be_truthy
    end
  end
end
