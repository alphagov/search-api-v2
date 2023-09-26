require "govuk_message_queue_consumer"
require "govuk_message_queue_consumer/test_helpers"

RSpec.describe PublishingEventPipeline::MessageProcessor do
  subject(:processor) { described_class.new(document_event_mapper:, repository:) }

  let(:repository) { double }
  let(:document_event_mapper) { ->(_) { event } }
  let(:event) { double(synchronize_to: nil) } # rubocop:disable RSpec/VerifiedDoubles (interface)

  it_behaves_like "a message queue processor"

  describe "when receiving an incoming message" do
    let(:message) { GovukMessageQueueConsumer::MockMessage.new(payload) }
    let(:payload) { { "I am" => "a message" } }

    before do
      allow(Rails.logger).to receive(:info)
    end

    it "acks incoming messages" do
      processor.process(message)

      expect(message).to be_acked
    end

    it "makes the event synchronize itself to the repository" do
      processor.process(message)

      expect(event).to have_received(:synchronize_to).with(repository)
    end

    context "when processing the event fails" do
      before do
        allow(document_event_mapper).to receive(:call).and_raise("Something went wrong")
      end

      it "bubbles the error up and does not ack the message" do
        expect { processor.process(message) }.to raise_error("Something went wrong")

        expect(message).not_to be_acked
      end
    end
  end
end
