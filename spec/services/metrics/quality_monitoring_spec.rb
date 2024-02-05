RSpec.describe Metrics::QualityMonitoring do
  subject(:quality_monitoring) { described_class.new(registry) }

  let(:registry) { double("registry") }
  let(:score_gauge) { double("score gauge") }
  let(:failure_gauge) { double("failure gauge") }

  before do
    allow(registry).to receive(:gauge)
      .with(:search_api_v2_quality_monitoring_score, anything).and_return(score_gauge)
    allow(registry).to receive(:gauge)
      .with(:search_api_v2_quality_monitoring_failures, anything).and_return(failure_gauge)

    allow(score_gauge).to receive(:set)
  end

  describe "#record_score" do
    it "records the score" do
      expect(score_gauge).to receive(:set)
        .with(0.5, labels: { dataset_type: "foo", dataset_name: "bar" })

      quality_monitoring.record_score(:foo, "bar", 0.5)
    end
  end

  describe "#record_failure_count" do
    it "records the failure count" do
      expect(failure_gauge).to receive(:set)
        .with(50, labels: { dataset_type: "foo", dataset_name: "bar" })

      quality_monitoring.record_failure_count(:foo, "bar", 50)
    end
  end
end
