RSpec.describe DiscoveryEngine::Quality::EvaluationsRunner do
  subject(:evaluations_runner) { described_class.new("explicit") }

  let(:last_month_partition_date) { Date.new(1979, 10, 1) }
  let(:month_before_last_partition_date) { Date.new(1979, 9, 1) }
  let(:explicit_query_set_last_month) { double("sample_query_set", table_id: "explicit", name: "/path/to/explicit-set-last_month") }
  let(:explicit_evaluation_of_last_month) { double("evaluation", list_evaluation_results: "detailed_metrics", formatted_create_time: "time-stamp", partition_date: last_month_partition_date) }
  let(:explicit_query_set_month_before_last) { double("sample_query_set", table_id: "explicit", name: "/path/to/explicit-month_before_last") }
  let(:explicit_evaluation_of_month_before_last) { double("evaluation", list_evaluation_results: "more_detailed_metrics", formatted_create_time: "time-stamp", partition_date: month_before_last_partition_date) }
  let(:gcp_bucket_exporter) { double("gcp_bucket_exporter") }

  before do
    allow(DiscoveryEngine::Quality::Evaluation)
      .to receive(:new)
      .with(explicit_query_set_last_month)
      .and_return(explicit_evaluation_of_last_month)

    allow(DiscoveryEngine::Quality::Evaluation)
     .to receive(:new)
     .with(explicit_query_set_month_before_last)
     .and_return(explicit_evaluation_of_month_before_last)

    { last_month: explicit_query_set_last_month,
      month_before_last: explicit_query_set_month_before_last }.each do |label, query_set|
      allow(DiscoveryEngine::Quality::SampleQuerySet)
        .to receive(:new)
        .with(table_id: "explicit", month_label: label)
        .and_return(query_set)
    end

    allow(DiscoveryEngine::Quality::GcpBucketExporter)
      .to receive(:new)
      .and_return(gcp_bucket_exporter)

    allow(gcp_bucket_exporter)
      .to receive(:send)
      .with(anything, anything, anything, anything)
      .and_return(true)
  end

  describe "#upload_detailed_metrics" do
    it "fetches explicit sample query sets for this month and the month before last" do
      evaluations_runner.upload_detailed_metrics

      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to have_received(:new)
        .with(table_id: "explicit", month_label: :last_month)
      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to have_received(:new)
        .with(table_id: "explicit", month_label: :month_before_last)
    end

    it "creates an evaluation of each sample query set" do
      evaluations_runner.upload_detailed_metrics

      expect(DiscoveryEngine::Quality::Evaluation)
      .to have_received(:new)
      .with(explicit_query_set_last_month)

      expect(DiscoveryEngine::Quality::Evaluation)
       .to have_received(:new)
       .with(explicit_query_set_month_before_last)
    end

    it "sends list_evaluation_results for each evaluation to a gcp bucket" do
      evaluations_runner.upload_detailed_metrics

      evaluations = [explicit_evaluation_of_last_month, explicit_evaluation_of_month_before_last]
      expect(evaluations).to all(have_received(:list_evaluation_results))
      expect(evaluations).to all(have_received(:formatted_create_time))

      expect(gcp_bucket_exporter).to have_received(:send).with("time-stamp", "explicit", last_month_partition_date, "detailed_metrics").once
      expect(gcp_bucket_exporter).to have_received(:send).with("time-stamp", "explicit", month_before_last_partition_date, "more_detailed_metrics").once
    end
  end
end
