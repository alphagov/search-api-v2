require "govuk_message_queue_consumer/test_helpers"

RSpec.describe PublishedDocumentsQueueConsumer do
  subject(:consumer) { described_class.new }

  it_behaves_like "a message queue processor"

  describe "when receiving an incoming message" do
    let(:message) { GovukMessageQueueConsumer::MockMessage.new(payload) }
    let(:payload) { { "hello" => "world" } }

    before do
      allow(Rails.logger).to receive(:info)
      consumer.process(message)
    end

    it "acks incoming messages" do
      expect(message).to be_acked
    end

    it "logs the payload of incoming messages" do
      expect(Rails.logger).to have_received(:info).with(payload)
    end
  end
end
