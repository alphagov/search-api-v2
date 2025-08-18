RSpec.describe DiscoveryEngine::Quality::Evaluations do
  subject(:evaluations) { described_class.new(metric_collector) }

  let(:metric_collector) { double("metric_collector") }
  let(:clickstream_evaluation) { double("evaluation") }
  let(:binary_evaluation) { double("evaluation") }
  let(:evaluation_response) { "anything" }
  let(:sample_query_sets) { double("sample_query_sets") }
  let(:clickstream_query_set) { double("sample_query_set", table_id: "clickstream", name: "/path/to/clickstream-set") }
  let(:binary_query_set) { double("sample_query_set", table_id: "binary", name: "/path/to/binary-set") }

  before do
    allow(DiscoveryEngine::Quality::Evaluation)
      .to receive(:new)
      .with(clickstream_query_set)
      .and_return(clickstream_evaluation)

    allow(DiscoveryEngine::Quality::Evaluation)
      .to receive(:new)
      .with(binary_query_set)
      .and_return(binary_evaluation)

    [clickstream_evaluation, binary_evaluation].each do |evaluation|
      allow(evaluation)
      .to receive(:quality_metrics)
      .and_return(evaluation_response)
    end

    %i[last_month month_before_last].each do |label|
      allow(metric_collector)
      .to receive(:record_evaluations)
      .with(evaluation_response, label, "clickstream")

      allow(metric_collector)
      .to receive(:record_evaluations)
      .with(evaluation_response, label, "binary")

      allow(DiscoveryEngine::Quality::SampleQuerySets)
      .to receive(:new)
      .with(label)
      .and_return(sample_query_sets)
    end

    allow(sample_query_sets)
      .to receive(:all)
      .and_return([clickstream_query_set, binary_query_set])
  end

  describe "#collect_all_quality_metrics" do
    it "fetches quality metrics for last-month and month-before-last for all tables" do
      evaluations.collect_all_quality_metrics

      expect(sample_query_sets)
        .to have_received(:all)
        .twice

      expect(binary_evaluation)
        .to have_received(:quality_metrics)
        .twice

      expect(clickstream_evaluation)
        .to have_received(:quality_metrics)
        .twice
    end

    context "when GCP returns an error" do
      let(:erroring_evaluation) { double("evaluation") }

      before do
        allow(DiscoveryEngine::Quality::Evaluation)
          .to receive(:new)
          .with(clickstream_query_set)
          .and_return(erroring_evaluation)

        allow(erroring_evaluation)
          .to receive(:quality_metrics)
          .and_raise(Google::Cloud::AlreadyExistsError)

        allow(GovukError).to receive(:notify)
      end

      it "notifies GovukError for each month label when evaluation creation fails" do
        evaluations.collect_all_quality_metrics

        expect(GovukError).to have_received(:notify)
          .with("No evaluation created for sample query set /path/to/clickstream-set. Month label: 'last_month')")
        expect(GovukError).to have_received(:notify)
          .with("No evaluation created for sample query set /path/to/clickstream-set. Month label: 'month_before_last')")
      end
    end

    context "when the table_id 'binary' is passed in" do
      before do
        allow(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .with(anything)
        .and_return(binary_query_set)
      end

      it "fetches quality metrics for last-month and month-before-last for binary tables" do
        evaluations.collect_all_quality_metrics("binary")

        expect(binary_evaluation)
          .to have_received(:quality_metrics)
          .twice
      end
    end

    context "when the table_id 'clickstream' is passed in" do
      before do
        allow(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .with(anything)
        .and_return(clickstream_query_set)
      end

      it "fetches quality metrics for last-month and month-before-last for clickstream tables" do
        evaluations.collect_all_quality_metrics("clickstream")

        expect(clickstream_evaluation)
          .to have_received(:quality_metrics)
          .twice
      end
    end
  end
end
