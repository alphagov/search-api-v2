RSpec.shared_examples "waits for running evaluations to complete" do |first_state, second_state, end_state|
  let(:active_evaluation) { double("evaluation", name: "/evaluations/active-evaluation") }
  let(:new_evaluation) do
    double("evaluation",
           state: :SUCCEEDED,
           quality_metrics: quality_metrics_response,
           name: new_evaluation_name,
           create_time: google_time_stamp,
           evaluation_spec: evaluation_spec)
  end
  let(:busy_evaluations_service) { double("busy_evaluations_service", create_evaluation: operation) }
  let(:operation) { double("operation", error?: false, wait_until_done!: true, results: operation_results) }
  let(:operation_results) { double("operation_results", name: new_evaluation.name) }

  before do
    allow(active_evaluation).to receive(:state).and_return(first_state, first_state, first_state, first_state, second_state, end_state)

    allow(DiscoveryEngine::Clients).to receive(:evaluation_service).and_return(busy_evaluations_service)

    allow(busy_evaluations_service)
      .to receive(:list_evaluations)
      .and_return([active_evaluation])

    allow(busy_evaluations_service)
      .to receive(:get_evaluation)
      .with(name: active_evaluation.name)
      .and_return(active_evaluation)

    allow(busy_evaluations_service)
      .to receive(:get_evaluation)
      .with(name: new_evaluation.name)
      .and_return(new_evaluation)
  end

  it "fetches all evaluations from the evaluations service" do
    evaluation.quality_metrics

    expect(busy_evaluations_service).to have_received(:list_evaluations).once
  end

  it "polls active evaluations 5 times waiting for them to complete" do
    evaluation.quality_metrics

    expect(Rails.logger).to have_received(:info)
      .with("Waiting for #{active_evaluation.name} to finish")

    expect(Kernel).to have_received(:sleep).exactly(4).times

    expect(active_evaluation).to have_received(:state).exactly(6).times

    expect(busy_evaluations_service).to have_received(:create_evaluation).once
  end
end
