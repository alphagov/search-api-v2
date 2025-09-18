RSpec.describe DiscoveryEngine::Quality::EvaluationsRunner do
  subject(:evaluations_runner) { described_class.new("explicit") }

  let(:table_id) { "explicit" }
  let(:last_month_partition_date) { Date.new(1979, 10, 1) }
  let(:month_before_last_partition_date) { Date.new(1979, 9, 1) }
  let(:query_set_last_month) { instance_double(DiscoveryEngine::Quality::SampleQuerySet, table_id:, name: "/path/to/#{table_id}-set-last_month", partition_date: last_month_partition_date) }
  let(:evaluation_of_last_month) { instance_double(DiscoveryEngine::Quality::Evaluation, list_evaluation_results: "detailed_metrics", formatted_create_time: "time-stamp", sample_set: query_set_last_month) }
  let(:query_set_month_before_last) { instance_double(DiscoveryEngine::Quality::SampleQuerySet, table_id:, name: "/path/to/#{table_id}-month_before_last", partition_date: month_before_last_partition_date) }
  let(:evaluation_of_month_before_last) { instance_double(DiscoveryEngine::Quality::Evaluation, list_evaluation_results: "more_detailed_metrics", formatted_create_time: "time-stamp", sample_set: query_set_month_before_last) }
  let(:gcp_bucket_exporter) { instance_double(DiscoveryEngine::Quality::GcpBucketExporter) }

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
        .with(table_id:, month_label: :last_month)
      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to have_received(:new)
        .with(table_id:, month_label: :month_before_last)
    end

    it "creates an evaluation of each sample query set" do
      evaluations_runner.upload_detailed_metrics

      expect(DiscoveryEngine::Quality::Evaluation)
      .to have_received(:new)
      .with(query_set_last_month)

      expect(DiscoveryEngine::Quality::Evaluation)
       .to have_received(:new)
       .with(query_set_month_before_last)
    end

    it "sends list_evaluation_results for each evaluation to a gcp bucket" do
      evaluations_runner.upload_detailed_metrics

      evaluations = [evaluation_of_last_month, evaluation_of_month_before_last]
      expect(evaluations).to all(have_received(:list_evaluation_results))
      expect(evaluations).to all(have_received(:formatted_create_time))

      expect(gcp_bucket_exporter).to have_received(:send).with("time-stamp", "explicit", last_month_partition_date, "detailed_metrics").once
      expect(gcp_bucket_exporter).to have_received(:send).with("time-stamp", "explicit", month_before_last_partition_date, "more_detailed_metrics").once
    end
  end
end
