require "govuk_message_queue_consumer/test_helpers"

RSpec.describe PublishedDocumentsQueueConsumer do
  subject(:consumer) { described_class.new }

  it_behaves_like "a message queue processor"

  describe "when receiving an incoming message" do
    let(:message) { GovukMessageQueueConsumer::MockMessage.new(payload) }
    let(:payload) { json_fixture_as_hash("message_queue/message.json") }

    before do
      allow(Rails.logger).to receive(:info)
      consumer.process(message)
    end

    it "acks incoming messages" do
      expect(message).to be_acked
    end

    it "logs the payload of incoming messages" do
      expect(Rails.logger).to have_received(:info)
        .with("Received message: f75d26a3-25a4-4c31-beea-a77cada4ce12 ('Ebola medal for over 3000 heroes')")
    end
  end
end
