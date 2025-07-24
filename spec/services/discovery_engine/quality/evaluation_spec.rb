RSpec.describe DiscoveryEngine::Quality::Evaluation do
  let(:sample_set) { instance_double(DiscoveryEngine::Quality::SampleQuerySet, name: "/set") }
  let(:evaluation) { described_class.new(sample_set) }

  describe "#fetch" do
    let(:quality_metrics) { double("quality_metrics", to_h: "some output") }
    let(:evaluation_service) { double("evaluation_service", create_evaluation: operation) }
    let(:operation) { double("operation", error?: false, wait_until_done!: true, results: response) }
    let(:response) { double("response", name: "/evaluations/1") }
    let(:evaluation_success) { double("evaluation", state: :SUCCEEDED, quality_metrics: quality_metrics) }
    let(:evaluation_pending) { double("evaluation", state: :PENDING) }

    before do
      allow(DiscoveryEngine::Clients).to receive(:evaluation_service).and_return(evaluation_service)
      allow(Rails.logger).to receive(:info)
    end

    context "when operation does not complete" do
      let(:error) { double("error", message: "An error message") }
      let(:operation) { double("operation", wait_until_done!: true, error?: true, error:) }

      it "raises an error" do
        expect { evaluation.fetch_quality_metrics }.to raise_error("An error message")
      end
    end

    context "when GCP returns an error" do
      let(:erroring_service) { double("evaluation") }

      before do
        allow(DiscoveryEngine::Clients).to receive(:evaluation_service).and_return(erroring_service)

        allow(erroring_service)
          .to receive(:create_evaluation)
          .with(anything)
          .and_raise(Google::Cloud::AlreadyExistsError)

        allow(Kernel).to receive(:sleep).with(3).and_return(true)
      end

      it "retries 3 times and then raises an error" do
        expect { evaluation.fetch_quality_metrics }.to raise_error(Google::Cloud::AlreadyExistsError)
        expect(erroring_service).to have_received(:create_evaluation).exactly(3).times
      end
    end

    context "when evaluation state is :SUCCEEDED" do
      before do
        allow(evaluation_service).to receive(:get_evaluation)
          .with(name: response.name)
          .and_return(evaluation_success)
      end

      it "calls the create_evaluation endpoint" do
        evaluation.fetch_quality_metrics

        expect(evaluation_service).to have_received(:create_evaluation).with(
          parent: Rails.application.config.discovery_engine_default_location_name,
          evaluation: {
            evaluation_spec: {
              query_set_spec: {
                sample_query_set: "/set",
              },
              search_request: {
                serving_config: ServingConfig.default.name,
              },
            },
          },
        )

        expect(Rails.logger).to have_received(:info)
          .with("Successfully created evaluation /evaluations/1")
      end

      it "fetches quality metrics" do
        evaluation.fetch_quality_metrics

        expect(evaluation_service).to have_received(:get_evaluation)
          .with(name: response.name)
          .once

        expect(evaluation_success)
          .to have_received(:quality_metrics)
          .once
      end
    end

    context "when evaluation state is :PENDING" do
      let(:evaluation_pending) { double("evaluation", state: :PENDING) }

      before do
        allow(evaluation_service).to receive(:get_evaluation)
          .with(name: response.name)
          .and_return(evaluation_pending, evaluation_success)

        allow(Kernel).to receive(:sleep).with(10).and_return(true)
      end

      it "sleeps for 10, then polls again" do
        evaluation.fetch_quality_metrics

        expect(evaluation_service).to have_received(:get_evaluation)
          .with(name: response.name)
          .twice

        expect(Kernel).to have_received(:sleep)

        expect(Rails.logger).to have_received(:info).with("Still waiting for evaluation to complete...")
      end
    end
  end
end
