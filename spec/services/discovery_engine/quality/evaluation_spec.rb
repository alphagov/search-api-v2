require_relative "shared_examples"

RSpec.describe DiscoveryEngine::Quality::Evaluation do
  let(:date) { Date.new(2025, 10, 1) }
  let(:sample_set) do
    instance_double(DiscoveryEngine::Quality::SampleQuerySet,
                    name: "/set",
                    display_name: "clickstream 2025-10",
                    partition_date: date)
  end
  let(:evaluation) { described_class.new(sample_set) }
  let(:evaluation_service) { double("evaluation_service", create_evaluation: operation, get_evaluation: new_evaluation) }
  let(:operation) { double("operation", error?: false, wait_until_done!: true, results: operation_results) }
  let(:operation_results) { double("operation_results", name: new_evaluation_name) }
  let(:new_evaluation_name) { "/evaluations/1" }
  let(:google_time_stamp) { double("google_time_stamp", nanos: 812_173_000, seconds: 1_753_600_645) }
  let(:search_request) do
    double("search_request",
           serving_config: "projects/780375417592/locations/global/collections/default_collection/engines/govuk_global/servingConfigs/default")
  end
  let(:evaluation_spec) do
    double("evaluation_spec",
           search_request: search_request)
  end
  let(:new_evaluation) do
    double("evaluation",
           state: :SUCCEEDED,
           quality_metrics: quality_metrics_response,
           name: new_evaluation_name,
           create_time: google_time_stamp,
           evaluation_spec: evaluation_spec)
  end

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
    allow(Kernel).to receive(:sleep).and_return(true)
  end

  describe "#quality_metrics" do
    context "when the evaluations service is busy" do
      # When the first check of state returns :PENDING or :RUNNING, the evaluation is added to the active_evaluations array.
      # In order for us to test that we wait for evaluations to finish, the second state must also be :PENDING or :RUNNING so
      # that we don't break on the first check of state in the wait_for_active_evaluations_to_finish while loop.

      it_behaves_like "waits for running evaluations to complete", :PENDING, :PENDING, :SUCCEEDED
      it_behaves_like "waits for running evaluations to complete", :RUNNING, :RUNNING, :SUCCEEDED
      it_behaves_like "waits for running evaluations to complete", :RUNNING, :RUNNING, :FAILED
      it_behaves_like "waits for running evaluations to complete", :PENDING, :RUNNING, :FAILED
      it_behaves_like "waits for running evaluations to complete", :PENDING, :RUNNING, :SUCCEEDED
    end

    context "when the evaluations service is not busy" do
      let(:complete_evaluation) { double("evaluation", state: :SUCCEEDED) }

      before do
        allow(evaluation_service).to receive(:list_evaluations).and_return([complete_evaluation])
      end

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
        before do
          allow(evaluation_service)
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
            .with(name: new_evaluation.name)

          expect(Rails.logger).to have_received(:info)
            .with("Successfully created an evaluation of sample set #{sample_set.display_name}")
        end

        it "fetches quality metrics" do
          evaluation.quality_metrics

          expect(new_evaluation)
            .to have_received(:quality_metrics)
            .once
        end

        it "calls quality_metrics on the memoised evaluation object" do
          evaluation.quality_metrics
          evaluation.quality_metrics

          expect(evaluation_service).to have_received(:create_evaluation)
          .once

          expect(evaluation_service).to have_received(:get_evaluation)
            .with(name: new_evaluation.name)
            .once
        end
      end

      context "when the evaluation is still being processed and has a state of :PENDING" do
        before do
          allow(new_evaluation).to receive(:state).and_return(:PENDING, :SUCCEEDED)
        end

        it "sleeps for 60, then polls again" do
          evaluation.quality_metrics

          expect(evaluation_service).to have_received(:get_evaluation)
            .with(name: new_evaluation.name)
            .twice

          expect(Kernel).to have_received(:sleep)

          expect(Rails.logger).to have_received(:info).with("Still waiting for evaluation to complete...")
        end
      end
    end
  end

  describe "#list_evaluation_results" do
    let(:list_evaluation_results) { double("list_evaluation_results") }
    let(:complete_evaluation) { double("evaluation", state: :SUCCEEDED) }

    before do
      allow(evaluation_service).to receive(:list_evaluations).and_return([complete_evaluation])
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

      expect(new_evaluation)
        .to have_received(:name)
        .exactly(3).times
    end
  end

  describe "#formatted_create_time" do
    let(:complete_evaluation) { double("evaluation", state: :SUCCEEDED) }

    before { allow(evaluation_service).to receive(:list_evaluations).and_return([complete_evaluation]) }

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
