RSpec.describe "Quality tasks" do
  let(:sample_query_set) { instance_double(DiscoveryEngine::Quality::SampleQuerySet) }
  let(:sample_query_sets) { instance_double(DiscoveryEngine::Quality::SampleQuerySets) }
  let(:evaluations) { instance_double(DiscoveryEngine::Quality::Evaluations) }
  let(:evaluations_runner) { instance_double(DiscoveryEngine::Quality::EvaluationsRunner) }
  let(:evaluation_response) { double }
  let(:registry) { double("registry", gauge: nil) }
  let(:metric_collector) { instance_double(Metrics::Evaluation) }

  describe "quality:setup_sample_query_sets" do
    before do
      Rake::Task["quality:setup_sample_query_sets"].reenable

      allow(DiscoveryEngine::Quality::SampleQuerySets)
      .to receive(:new)
      .with(:last_month)
      .and_return(sample_query_sets)

      allow(sample_query_sets)
      .to receive(:create_and_import_all)
    end

    it "creates and imports a sample set" do
      expect(sample_query_sets)
        .to receive(:create_and_import_all)
        .once
      Rake::Task["quality:setup_sample_query_sets"].invoke
    end
  end

  describe "quality:setup_sample_query_set" do
    before do
      Rake::Task["quality:setup_sample_query_set"].reenable

      allow(DiscoveryEngine::Quality::SampleQuerySet)
      .to receive(:new)
      .with(month: 1, year: 2025, table_id: "clickstream")
      .and_return(sample_query_set)
    end

    it "creates and imports a sample set" do
      expect(sample_query_set)
        .to receive(:create_and_import_queries)
        .once
      Rake::Task["quality:setup_sample_query_set"].invoke("2025", "1", "clickstream")
    end

    it "raises an error unless table_id is provided" do
      message = "table id is a required argument"
      expect {
        Rake::Task["quality:setup_sample_query_set"].invoke("2025", "1")
      }.to raise_error(message)
    end

    it "raises an error unless year and month are provided" do
      message = "year and month are required arguments"
      expect {
        Rake::Task["quality:setup_sample_query_set"].invoke("clickstream")
      }.to raise_error(message)
    end

    it "raises an error if year and month are not provided in YYYY MM order" do
      message = "arguments must be provided in YYYY MM order"
      expect {
        Rake::Task["quality:setup_sample_query_set"].invoke("05", "2025", "clickstream")
      }.to raise_error(message)
    end
  end

  describe "quality:report_quality_metrics" do
    let(:push_client) { double("push_client", add: nil) }
    let(:logger_message) { "Getting ready to fetch quality metrics for all datasets" }

    before do
      Rake::Task["quality:report_quality_metrics"].reenable

      allow(DiscoveryEngine::Quality::Evaluations)
          .to receive(:new)
          .with(metric_collector)
          .and_return(evaluations)

      allow(Prometheus::Client)
        .to receive(:registry)
        .and_return(registry)

      allow(Prometheus::Client::Push)
        .to receive(:new)
        .and_return(push_client)

      allow(Metrics::Evaluation)
        .to receive(:new)
        .with(registry)
        .and_return(metric_collector)

      allow(Rails.logger).to receive(:info)
    end

    it "reports quality metrics to prometheus" do
      ClimateControl.modify PROMETHEUS_PUSHGATEWAY_URL: "https://www.something.example.org" do
        expect(evaluations)
          .to receive(:collect_all_quality_metrics)
          .once
        expect(Rails.logger)
          .to receive(:info)
          .with(logger_message)
        expect(push_client)
          .to receive(:add)
          .with(registry)
        Rake::Task["quality:report_quality_metrics"].invoke
      end
    end

    context "when a table_id is passed in" do
      let(:logger_message) { "Getting ready to fetch quality metrics for binary datasets" }

      before do
        Rake::Task["quality:report_quality_metrics"].reenable
        allow(Rails.logger).to receive(:info)
      end

      it "reports quality metrics for the given table only" do
        ClimateControl.modify PROMETHEUS_PUSHGATEWAY_URL: "https://www.something.example.org" do
          expect(Rails.logger)
            .to receive(:info)
            .with(logger_message)

          expect(evaluations)
            .to receive(:collect_all_quality_metrics)
            .with("binary")
            .once
          Rake::Task["quality:report_quality_metrics"].invoke("binary")
        end
      end
    end
  end

  describe "quality:upload_and_report_metrics" do
    context "when a table_id is passed in" do
      let(:logger_message) { "Getting ready to upload detailed metrics for explicit datasets" }

      before do
        allow(DiscoveryEngine::Quality::EvaluationsRunner)
          .to receive(:new)
          .with("explicit")
          .and_return(evaluations_runner)

        allow(evaluations_runner).to receive(:upload_and_report_metrics)
        allow(Rails.logger)
          .to receive(:info)

        Rake::Task["quality:upload_and_report_metrics"].reenable
      end

      it "sends .upload_and_report_metrics to the evaluations_runner" do
        expect(evaluations_runner).to receive(:upload_and_report_metrics)
        expect(Rails.logger).to receive(:info).with(logger_message)

        Rake::Task["quality:upload_and_report_metrics"].invoke("explicit")
      end

      it "raises an error if the table id is invalid" do
        expect {
          Rake::Task["quality:upload_and_report_metrics"].invoke("nope")
        }.to raise_error("invalid table id")
      end
    end

    context "when no table id is passed in" do
      before do
        allow(DiscoveryEngine::Quality::EvaluationsRunner)
          .to receive(:new)
          .with(anything)
          .and_return(evaluations_runner)

        allow(evaluations_runner).to receive(:upload_and_report_metrics)

        Rake::Task["quality:upload_and_report_metrics"].reenable
      end

      it "passes all valid table ids to the evaluations_runner" do
        Rake::Task["quality:upload_and_report_metrics"].invoke
        %w[clickstream binary explicit].each do |table_id|
          expect(DiscoveryEngine::Quality::EvaluationsRunner)
            .to have_received(:new)
            .with(table_id)
        end

        expect(evaluations_runner)
          .to have_received(:upload_and_report_metrics)
          .exactly(3).times
      end
    end
  end
end
