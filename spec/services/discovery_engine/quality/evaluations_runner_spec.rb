RSpec.describe DiscoveryEngine::Quality::EvaluationsRunner do
  subject(:evaluations_runner) { described_class.new("explicit") }

  let(:table_id) { "explicit" }
  let(:last_month_partition_date) { Date.new(1979, 10, 1) }
  let(:month_before_last_partition_date) { Date.new(1979, 9, 1) }
  let(:query_set_last_month) do
    instance_double(DiscoveryEngine::Quality::SampleQuerySet,
                    table_id:,
                    name: "/path/to/#{table_id}-set-last_month",
                    partition_date: last_month_partition_date,
                    month_label: :last_month)
  end
  let(:evaluation_of_last_month) do
    instance_double(DiscoveryEngine::Quality::Evaluation,
                    list_evaluation_results: "detailed_metrics",
                    formatted_create_time: "time-stamp",
                    sample_set: query_set_last_month,
                    quality_metrics: "quality_metrics")
  end
  let(:query_set_month_before_last) do
    instance_double(DiscoveryEngine::Quality::SampleQuerySet,
                    table_id:,
                    name: "/path/to/#{table_id}-month_before_last",
                    partition_date: month_before_last_partition_date,
                    month_label: :month_before_last)
  end
  let(:evaluation_of_month_before_last) do
    instance_double(DiscoveryEngine::Quality::Evaluation,
                    list_evaluation_results: "more_detailed_metrics",
                    formatted_create_time: "time-stamp",
                    sample_set: query_set_month_before_last,
                    quality_metrics: "quality_metrics")
  end
  let(:gcp_bucket_exporter) { instance_double(DiscoveryEngine::Quality::GcpBucketExporter) }
  let(:prometheus_reporter) { instance_double(DiscoveryEngine::Quality::PrometheusReporter) }
  let(:evaluation_service) { double("evaluation_service") }
  let(:evaluations_list) do
    [
      double("evaluation", name: "/evaluations/1", state: :SUCCEEDED),
    ]
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

    allow(DiscoveryEngine::Clients).to receive(:evaluation_service).and_return(evaluation_service)

    allow(evaluation_service).to receive(:list_evaluations)
      .with(parent: Rails.application.config.discovery_engine_default_location_name)
      .and_return(evaluations_list)
  end

  describe "#upload_and_report_metrics" do
    it "fetches explicit sample query sets for this month and the month before last" do
      evaluations_runner.upload_and_report_metrics

      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to have_received(:new)
        .with(table_id:, month_label: :last_month)
      expect(DiscoveryEngine::Quality::SampleQuerySet)
        .to have_received(:new)
        .with(table_id:, month_label: :month_before_last)
    end

    it "creates an evaluation of each sample query set" do
      evaluations_runner.upload_and_report_metrics

      expect(DiscoveryEngine::Quality::Evaluation)
      .to have_received(:new)
      .with(query_set_last_month)

      expect(DiscoveryEngine::Quality::Evaluation)
       .to have_received(:new)
       .with(query_set_month_before_last)
    end

    it "sends list_evaluation_results for each evaluation to a gcp bucket" do
      evaluations_runner.upload_and_report_metrics

      evaluations = [evaluation_of_last_month, evaluation_of_month_before_last]
      expect(evaluations).to all(have_received(:list_evaluation_results))
      expect(evaluations).to all(have_received(:formatted_create_time))

      expect(gcp_bucket_exporter).to have_received(:send).with("time-stamp", "explicit", last_month_partition_date, "detailed_metrics").once
      expect(gcp_bucket_exporter).to have_received(:send).with("time-stamp", "explicit", month_before_last_partition_date, "more_detailed_metrics").once
    end

    it "sends quality metrics for each evaluation to prometheus" do
      evaluations_runner.upload_and_report_metrics

      evaluations = [evaluation_of_last_month, evaluation_of_month_before_last]
      expect(evaluations).to all(have_received(:quality_metrics))

      expect(prometheus_reporter).to have_received(:send).with("quality_metrics", :last_month, "explicit").once
      expect(prometheus_reporter).to have_received(:send).with("quality_metrics", :month_before_last, "explicit").once
    end

    it "checks if any evaluations are running" do
      evaluations_runner.upload_and_report_metrics

      expect(evaluation_service).to have_received(:list_evaluations).with(
        parent: Rails.application.config.discovery_engine_default_location_name,
      ).at_least(:once)
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
