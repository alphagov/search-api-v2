RSpec.describe DiscoveryEngine::Quality::Evaluations do
  subject(:evaluations) { described_class.new(month_label, metric_collector) }

  let(:month_label) { :last_month }
  let(:metric_collector) { double("metric_collector") }
  let(:evaluation) { double("evaluation") }
  let(:evaluation_response) { "amything" }
  let(:sample_query_sets) { double("sample_query_sets") }
  let(:sample_query_set) { double("sample_query_set") }

  before do
    allow(DiscoveryEngine::Quality::Evaluation)
      .to receive(:new)
      .with(sample_query_set)
      .and_return(evaluation)

    allow(evaluation)
      .to receive(:fetch_quality_metrics)
      .and_return(evaluation_response)

    allow(metric_collector)
      .to receive(:record_evaluations)
      .with(evaluation_response, month_label)

    allow(DiscoveryEngine::Quality::SampleQuerySets)
      .to receive(:new)
      .with(anything)
      .and_return(sample_query_sets)

    allow(sample_query_sets)
      .to receive(:all)
      .and_return([sample_query_set, sample_query_set])
  end

  describe "#collect_all_quality_metrics" do
    it "sends #fetch_quality_metrics to the Evaluation class for all sample query sets" do
      evaluations.collect_all_quality_metrics

      expect(evaluation)
        .to have_received(:fetch_quality_metrics)
        .twice
    end
  end
end
