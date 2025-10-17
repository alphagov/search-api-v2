RSpec.describe DiscoveryEngine::Quality::EvaluationsRunner do
  subject(:evaluations_runner) { described_class.new("explicit") }

  let(:table_id) { "explicit" }
  let(:this_month_partition_date) { Date.new(1979, 10, 1) }
  let(:last_month_partition_date) { Date.new(1979, 9, 1) }
  let(:query_set_this_month) do
    instance_double(DiscoveryEngine::Quality::SampleQuerySet,
                    table_id:,
                    name: "/path/to/#{table_id}-set-this_month",
                    partition_date: this_month_partition_date,
                    month_label: :this_month)
  end
  let(:evaluation_of_this_month_sample_query_set) do
    instance_double(DiscoveryEngine::Quality::Evaluation,
                    list_evaluation_results: "detailed_metrics",
                    formatted_create_time: "time-stamp",
                    sample_set: query_set_this_month,
                    quality_metrics: "quality_metrics")
  end
  let(:query_set_last_month) do
    instance_double(DiscoveryEngine::Quality::SampleQuerySet,
                    table_id:,
                    name: "/path/to/#{table_id}-last_month",
                    partition_date: last_month_partition_date,
                    month_label: :last_month)
  end
  let(:evaluation_of_last_month_sample_query_set) do
    instance_double(DiscoveryEngine::Quality::Evaluation,
                    list_evaluation_results: "more_detailed_metrics",
                    formatted_create_time: "time-stamp",
                    sample_set: query_set_last_month,
                    quality_metrics: "quality_metrics")
  end
  let(:gcp_bucket_exporter) { instance_double(DiscoveryEngine::Quality::GcpBucketExporter) }
  let(:prometheus_reporter) { instance_double(DiscoveryEngine::Quality::PrometheusReporter) }

  before do
    allow(DiscoveryEngine::Quality::Evaluation)
      .to receive(:new)
      .with(query_set_this_month)
      .and_return(evaluation_of_this_month_sample_query_set)

    allow(DiscoveryEngine::Quality::Evaluation)
     .to receive(:new)
     .with(query_set_last_month)
     .and_return(evaluation_of_last_month_sample_query_set)

    { this_month: query_set_this_month,
      last_month: query_set_last_month }.each do |label, query_set|
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

    allow(DiscoveryEngine::Quality::PrometheusReporter)
      .to receive(:new)
      .and_return(prometheus_reporter)

    allow(prometheus_reporter)
      .to receive(:send)
      .with(anything, anything, anything)
      .and_return(true)

    allow(Kernel).to receive(:sleep).with(10).and_return(true)
  end

  describe "#upload_and_report_metrics" do
    it "fetches explicit sample query sets for this month and last month" do
      evaluations_runner.upload_and_report_metrics

      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to have_received(:new)
        .with(table_id:, month_label: :this_month)
        .once
      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to have_received(:new)
        .with(table_id:, month_label: :last_month)
        .once
    end

    it "creates an evaluation of each sample query set" do
      evaluations_runner.upload_and_report_metrics

      expect(DiscoveryEngine::Quality::Evaluation)
      .to have_received(:new)
      .with(query_set_this_month)

      expect(DiscoveryEngine::Quality::Evaluation)
       .to have_received(:new)
       .with(query_set_last_month)
    end

    it "sends list_evaluation_results for each evaluation to a gcp bucket" do
      evaluations_runner.upload_and_report_metrics

      evaluations = [evaluation_of_this_month_sample_query_set, evaluation_of_last_month_sample_query_set]
      expect(evaluations).to all(have_received(:list_evaluation_results))
      expect(evaluations).to all(have_received(:formatted_create_time))

      expect(gcp_bucket_exporter).to have_received(:send).with("time-stamp", "explicit", this_month_partition_date, "detailed_metrics").once
      expect(gcp_bucket_exporter).to have_received(:send).with("time-stamp", "explicit", last_month_partition_date, "more_detailed_metrics").once
    end

    it "sends quality metrics for each evaluation to prometheus" do
      evaluations_runner.upload_and_report_metrics

      evaluations = [evaluation_of_this_month_sample_query_set, evaluation_of_last_month_sample_query_set]
      expect(evaluations).to all(have_received(:quality_metrics))

      expect(prometheus_reporter).to have_received(:send).with("quality_metrics", :this_month, "explicit").once
      expect(prometheus_reporter).to have_received(:send).with("quality_metrics", :last_month, "explicit").once
    end

    context "when environment is development" do
      let(:warning_message) { "Skipping push of evaluations to Prometheus push gateway" }

      before do
        allow(Rails.logger).to receive(:warn)
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "skips sending quality metrics to Prometheus" do
        evaluations_runner.upload_and_report_metrics

        expect(Rails.logger)
          .to have_received(:warn)
          .with(warning_message).twice

        expect(prometheus_reporter).not_to have_received(:send)
      end
    end
  end
end
