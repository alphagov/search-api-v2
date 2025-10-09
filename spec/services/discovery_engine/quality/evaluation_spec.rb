RSpec.describe DiscoveryEngine::Quality::Evaluation do
  let(:date) { Date.new(2025, 10, 1) }
  let(:sample_set) do
    instance_double(DiscoveryEngine::Quality::SampleQuerySet,
                    name: "/set",
                    display_name: "clickstream 2025-10",
                    partition_date: date)
  end
  let(:evaluation) { described_class.new(sample_set) }
  let(:evaluation_service) { double("evaluation_service", create_evaluation: operation, get_evaluation: evaluation_success) }
  let(:operation) { double("operation", error?: false, wait_until_done!: true, results: operation_results) }
  let(:operation_results) { double("operation_results", name: "/evaluations/1") }
  let(:google_time_stamp) { double("google_time_stamp", nanos: 812_173_000, seconds: 1_753_600_645) }
  let(:search_request) do
    double("search_request",
           serving_config: "projects/780375417592/locations/global/collections/default_collection/engines/govuk_global/servingConfigs/default")
  end
  let(:evaluation_spec) do
    double("evaluation_spec",
           search_request: search_request)
  end
  let(:evaluation_success) do
    double("evaluation",
           state: :SUCCEEDED,
           quality_metrics: quality_metrics_response,
           name: "/evaluations/1",
           create_time: google_time_stamp,
           evaluation_spec: evaluation_spec)
  end
  let(:evaluation_pending) { double("evaluation", state: :PENDING) }

  let(:quality_metrics_response) do
    {
      "doc_recall" => {
        "top_1" => 0.851,
        "top_3" => 0.93,
        "top_5" => 0.939,
        "top_10" => 0.945,
      },
      "doc_precision" => {
        "top_1" => 0.851,
        "top_3" => 0.3713333333333329,
        "top_5" => 0.22840000000000052,
        "top_10" => 0.11520000000000026,
      },
      "doc_ndcg" => {
        "top_1" => 0.851,
        "top_3" => 0.8809067030461095,
        "top_5" => 0.8888468583490955,
        "top_10" => 0.8913925917320329,
      },
    }
  end

  before do
    allow(DiscoveryEngine::Clients).to receive(:evaluation_service).and_return(evaluation_service)
    allow(Rails.logger).to receive(:info)
    allow(Kernel).to receive(:sleep).with(10).and_return(true)
  end

  describe "#quality_metrics" do
    it "sends a create evaluation request to the evaluations service" do
      evaluation.quality_metrics

      expect(evaluation_service)
        .to have_received(:create_evaluation)
        .with(
          parent: Rails.application.config.discovery_engine_default_location_name,
          evaluation: {
            evaluation_spec: {
              query_set_spec: {
                sample_query_set: sample_set.name,
              },
              search_request: {
                serving_config: ServingConfig.default.name,
              },
            },
          },
        )
    end

    context "when the create evaluations request does not complete" do
      let(:error) { double("error", message: "An error message") }
      let(:operation) { double("operation", wait_until_done!: true, error?: true, error:) }

      it "raises an error" do
        expect { evaluation.quality_metrics }.to raise_error("An error message")
      end
    end

    context "when GCP returns an AlreadyExistsError" do
      let(:erroring_evaluation_service) { double("erroring_evaluation_service") }

      before do
        allow(DiscoveryEngine::Clients).to receive(:evaluation_service).and_return(erroring_evaluation_service)

        allow(erroring_evaluation_service)
          .to receive(:create_evaluation)
          .with(anything)
          .and_raise(Google::Cloud::AlreadyExistsError)

        allow(GovukError).to receive(:notify)
      end

      it "logs then raises the error" do
        expect { evaluation.quality_metrics }.to raise_error(Google::Cloud::AlreadyExistsError)

        expect(GovukError).to have_received(:notify)
          .with("No evaluation created of sample set clickstream 2025-10 (Google::Cloud::AlreadyExistsError)")
      end
    end

    context "when the evaluation completes and has a state of :SUCCEEDED" do
      it "fetches the evaluation" do
        evaluation.quality_metrics

        expect(evaluation_service).to have_received(:get_evaluation)
          .with(name: evaluation_success.name)

        expect(Rails.logger).to have_received(:info)
          .with("Successfully created an evaluation of sample set clickstream 2025-10")
      end

      it "fetches quality metrics" do
        evaluation.quality_metrics

        expect(evaluation_success)
          .to have_received(:quality_metrics)
          .once
      end

      it "calls quality_metrics on the memoised evaluation object" do
        evaluation.quality_metrics
        evaluation.quality_metrics

        expect(evaluation_service).to have_received(:create_evaluation)
         .once

        expect(evaluation_service).to have_received(:get_evaluation)
          .with(name: evaluation_success.name)
          .once
      end
    end

    context "when the evaluation is still being processed and has a state of :PENDING" do
      let(:evaluation_pending) { double("evaluation", state: :PENDING) }

      before do
        allow(evaluation_service).to receive(:get_evaluation)
          .with(name: evaluation_success.name)
          .and_return(evaluation_pending, evaluation_success)
      end

      it "sleeps for 10, then polls again" do
        evaluation.quality_metrics

        expect(evaluation_service).to have_received(:get_evaluation)
          .with(name: evaluation_success.name)
          .twice

        expect(Kernel).to have_received(:sleep)

        expect(Rails.logger).to have_received(:info).with("Still waiting for evaluation to complete...")
      end
    end
  end

  describe "#list_evaluation_results" do
    let(:list_evaluation_results) { double("list_evaluation_results") }

    before do
      allow(DiscoveryEngine::Quality::ListEvaluationResults)
        .to receive(:new)
        .with(anything, anything, anything)
        .and_return(list_evaluation_results)

      allow(list_evaluation_results)
        .to receive(:formatted_json)
    end

    it "creates an evaluation first" do
      evaluation.list_evaluation_results

      expect(evaluation_service).to have_received(:create_evaluation).once
      expect(evaluation_service).to have_received(:get_evaluation).once

      expect(list_evaluation_results).to have_received(:formatted_json)
    end

    it "uses the memoised api response if an evaluation already exists" do
      3.times { evaluation.list_evaluation_results }

      expect(evaluation_service).to have_received(:create_evaluation).once
      expect(evaluation_service).to have_received(:get_evaluation).once

      expect(evaluation_success)
        .to have_received(:name)
        .exactly(3).times
    end
  end

  describe "#formatted_create_time" do
    before do
      allow(evaluation_service).to receive(:get_evaluation)
        .with(name: evaluation_success.name)
        .and_return(evaluation_success)
    end

    it "formats the create_time stamp from the google response" do
      evaluation.quality_metrics
      expect(evaluation.formatted_create_time).to eq("2025-07-27 07:17:25")
    end

    it "raises an error if an evaluation doesn't exist yet" do
      message = "Error: cannot provide create time of an evaluation unless one exists"
      expect { evaluation.formatted_create_time }.to raise_error(message)
    end
  end
end
