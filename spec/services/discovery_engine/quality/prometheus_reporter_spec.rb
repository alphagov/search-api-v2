RSpec.describe DiscoveryEngine::Quality::PrometheusReporter do
  subject(:prometheus_reporter) { described_class.new }

  let(:a_label) { "a_label" }
  let(:another_label) { "another_label" }
  let(:quality_metrics) { "quality_metrics" }

  describe "send" do
    it "is to be implemented" do
      expect(prometheus_reporter.send(quality_metrics, a_label, another_label)).to eq "to be implemented"
    end
  end
end
