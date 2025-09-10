RSpec.shared_context "with a table_id" do
  let(:last_month) { Date.new(1979, 10, 1) }
  let(:month_before_last) { Date.new(1979, 9, 1) }
  let(:query_set_last_month) { double("sample_query_set", table_id:, name: "/path/to/#{table_id}-set-last_month") }
  let(:evaluation_of_last_month) { double("evaluation", list_evaluation_results: "detailed_metrics", formatted_create_time: "time-stamp", partition_date: last_month) }
  let(:query_set_month_before_last) { double("sample_query_set", table_id:, name: "/path/to/#{table_id}-month_before_last") }
  let(:evaluation_of_month_before_last) { double("evaluation", list_evaluation_results: "more_detailed_metrics", formatted_create_time: "time-stamp", partition_date: month_before_last) }

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

RSpec.shared_examples "creates sample query sets and evaluations" do |table_id|
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

    describe "#upload_detailed_metrics" do
      before do
        allow(DiscoveryEngine::Quality::GcpBucketExporter)
          .to receive(:new)
          .and_return(gcp_bucket_exporter)

        allow(gcp_bucket_exporter)
          .to receive(:send)
          .with(anything, anything, anything, anything)
          .and_return(true)
        evaluations_runner.upload_detailed_metrics
      end

      it_behaves_like "creates sample query sets and evaluations", "explicit"

      it "fetches list evaluation results and a time_stamp from each evaluation" do
        evaluations = [evaluation_of_last_month, evaluation_of_month_before_last]
        expect(evaluations).to all(have_received(:list_evaluation_results))
        expect(evaluations).to all(have_received(:formatted_create_time))
      end
    end

    describe "#upload_and_report_metrics" do
      it "is to be implemented" do
        expect(evaluations_runner.upload_and_report_metrics).to be_truthy
      end
    end
  end
end
