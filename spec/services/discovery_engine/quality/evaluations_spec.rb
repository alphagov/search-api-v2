RSpec.describe DiscoveryEngine::Quality::Evaluations do
  subject(:evaluations) { described_class.new(metric_collector) }

  let(:metric_collector) { double("metric_collector") }
  let(:evaluation) { double("evaluation") }
  let(:evaluation_response) { "anything" }
  let(:sample_query_sets) { double("sample_query_sets") }
  let(:sample_query_set) { double("sample_query_set", table_id: "clickstream", name: "/path/to/set") }

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
      .with(evaluation_response, :last_month, "clickstream")

    allow(metric_collector)
      .to receive(:record_evaluations)
      .with(evaluation_response, :month_before_last, "clickstream")

    allow(DiscoveryEngine::Quality::SampleQuerySets)
      .to receive(:new)
      .with(anything)
      .and_return(sample_query_sets)

    allow(sample_query_sets)
      .to receive(:all)
      .and_return([sample_query_set])
  end

  describe "#collect_all_quality_metrics" do
    it "sends #fetch_quality_metrics to the Evaluation class for all sample query sets" do
      evaluations.collect_all_quality_metrics

      expect(evaluation)
        .to have_received(:fetch_quality_metrics)
        .twice
    end

    context "when GCP returns an error" do
      let(:erroring_evaluation) { double("evaluation") }

      before do
        allow(DiscoveryEngine::Quality::Evaluation)
          .to receive(:new)
          .with(sample_query_set)
          .and_return(erroring_evaluation)

        allow(erroring_evaluation)
          .to receive(:fetch_quality_metrics)
          .and_raise(Google::Cloud::AlreadyExistsError)

        allow(GovukError).to receive(:notify)
      end

      it "notifies GovukError for each month label when evaluation creation fails" do
        evaluations.collect_all_quality_metrics

        expect(GovukError).to have_received(:notify)
          .with("No evaluation created for sample query set /path/to/set. Month label: 'last_month')")
        expect(GovukError).to have_received(:notify)
          .with("No evaluation created for sample query set /path/to/set. Month label: 'month_before_last')")
      end
    end
  end
end
