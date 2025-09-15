RSpec.shared_context "with a table_id" do
  let(:last_month_partition_date) { Date.new(1979, 10, 1) }
  let(:month_before_last_partition_date) { Date.new(1979, 9, 1) }
  let(:query_set_last_month) { double("sample_query_set", table_id:, name: "/path/to/#{table_id}-set-last_month") }
  let(:evaluation_of_last_month) do
    double("evaluation",
           list_evaluation_results: "detailed_metrics",
           formatted_create_time: "time-stamp",
           partition_date: last_month_partition_date,
           quality_metrics: "quality_metrics")
  end
  let(:query_set_month_before_last) { double("sample_query_set", table_id:, name: "/path/to/#{table_id}-month_before_last") }
  let(:evaluation_of_month_before_last) do
    double("evaluation",
           list_evaluation_results: "more_detailed_metrics",
           formatted_create_time: "time-stamp",
           partition_date: month_before_last_partition_date,
           quality_metrics: "quality_metrics")
  end

  before do
    allow(DiscoveryEngine::Quality::Evaluation)
      .to receive(:new)
      .with(query_set_last_month)
      .and_return(evaluation_of_last_month)

    allow(DiscoveryEngine::Quality::Evaluation)
     .to receive(:new)
     .with(query_set_month_before_last)
     .and_return(evaluation_of_month_before_last)

    { last_month: query_set_last_month,
      month_before_last: query_set_month_before_last }.each do |label, query_set|
      allow(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .with(table_id:, month_label: label)
        .and_return(query_set)
    end
  end
end

RSpec.shared_examples "creates sample query sets and evaluations" do |method|
  before do
    evaluations_runner.send(method)
  end

  it "fetches explicit sample query sets for this month and the month before last" do
    expect(DiscoveryEngine::Quality::SampleQuerySet)
      .to have_received(:new)
      .with(table_id:, month_label: :last_month)
    expect(DiscoveryEngine::Quality::SampleQuerySet)
      .to have_received(:new)
      .with(table_id:, month_label: :month_before_last)
  end

  it "creates an evaluation of each sample query set" do
    expect(DiscoveryEngine::Quality::Evaluation)
    .to have_received(:new)
    .with(query_set_last_month)

    expect(DiscoveryEngine::Quality::Evaluation)
      .to have_received(:new)
      .with(query_set_month_before_last)
  end
end

RSpec.describe DiscoveryEngine::Quality::EvaluationsRunner do
  subject(:evaluations_runner) { described_class.new(table_id) }

  context "when a table id is passed in" do
    include_context "with a table_id"

    let(:table_id) { "explicit" }
    let(:gcp_bucket_exporter) { double("gcp_bucket_exporter") }
    let(:prometheus_reporter) { double("prometheus_reporter") }

    before do
      allow(DiscoveryEngine::Quality::GcpBucketExporter)
        .to receive(:new)
        .and_return(gcp_bucket_exporter)

      allow(gcp_bucket_exporter)
        .to receive(:send)
        .with(anything, anything, anything, anything)
        .and_return(true)

      allow(DiscoveryEngine::Quality::PrometheusReporter)
        .to receive(:new)
        .and_return(prometheus_reporter)

      allow(prometheus_reporter)
        .to receive(:send)
        .with(anything, anything)
        .and_return(true)
    end

    describe "#upload_detailed_metrics" do
      it_behaves_like "creates sample query sets and evaluations", :upload_detailed_metrics

      it "sends list_evaluation_results for each evaluation to a gcp bucket" do
        evaluations = [evaluation_of_last_month, evaluation_of_month_before_last]

        evaluations_runner.upload_detailed_metrics

        expect(evaluations).to all(have_received(:list_evaluation_results))
        expect(evaluations).to all(have_received(:formatted_create_time))

        expect(gcp_bucket_exporter).to have_received(:send).with("time-stamp", "explicit", last_month_partition_date, "detailed_metrics").once
        expect(gcp_bucket_exporter).to have_received(:send).with("time-stamp", "explicit", month_before_last_partition_date, "more_detailed_metrics").once
      end
    end

    describe "#upload_and_report_metrics" do
      it_behaves_like "creates sample query sets and evaluations", :upload_and_report_metrics

      it "sends quality_metrics for each evaluation to prometheus" do
        evaluations = [evaluation_of_last_month, evaluation_of_month_before_last]

        evaluations_runner.upload_and_report_metrics

        expect(evaluations).to all(have_received(:quality_metrics))

        expect(prometheus_reporter).to have_received(:send).with("quality_metrics", evaluation_of_last_month).once
        expect(prometheus_reporter).to have_received(:send).with("quality_metrics", evaluation_of_month_before_last).once
      end
    end
  end
end
