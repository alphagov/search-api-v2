require "publish_event_pipeline/message_processor"

require "govuk_message_queue_consumer"
require "govuk_message_queue_consumer/test_helpers"

RSpec.describe PublishEventPipeline::MessageProcessor do
  describe ".process" do
    subject(:class_acting_as_processor) { described_class }

    it_behaves_like "a message queue processor"
  end

  describe "when receiving an incoming message" do
    subject(:command) { described_class.new(message) }

    let(:message) { GovukMessageQueueConsumer::MockMessage.new(payload) }
    let(:payload) { json_fixture_as_hash("message_queue/message.json") }

    before do
      allow(Rails.logger).to receive(:info)
    end

    it "acks incoming messages" do
      command.call
      expect(message).to be_acked
    end

    it "logs the payload of incoming messages" do
      command.call
      expect(Rails.logger).to have_received(:info)
        .with("Received republish: f75d26a3-25a4-4c31-beea-a77cada4ce12 ('Ebola medal for over 3000 heroes')")
    end

    context "when the message is invalid" do
      let(:payload) { { "I am" => "not valid" } }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error" do
        command.call
        expect(Rails.logger).to have_received(:error)
      end
    end
  end
end
