require "govuk_message_queue_consumer/test_helpers"

RSpec.describe PublishingApiMessageProcessor do
  subject(:processor) { described_class.new }

  let(:document) { double(synchronize: nil) }

  it_behaves_like "a message queue processor"

  describe "when receiving an incoming message" do
    let(:message) { GovukMessageQueueConsumer::MockMessage.new(payload) }
    let(:payload) { { "I am": "a message" } }
    let(:logger) { instance_double(Logger, info: nil, error: nil) }

    before do
      allow(PublishingApiDocument).to receive(:for).with(payload).and_return(document)

      allow(Rails).to receive(:logger).and_return(logger)
      allow(Rails.logger).to receive(:info)
      allow(GovukError).to receive(:notify)
    end

    it "acks incoming messages" do
      processor.process(message)

      expect(message).to be_acked
    end

    it "makes the document synchronize itself" do
      processor.process(message)

      expect(document).to have_received(:synchronize)
    end

    context "when creating the document fails" do
      let(:error) { RuntimeError.new("Could not process") }

      before do
        allow(PublishingApiDocument).to receive(:for).and_raise(error)

        allow(GovukError).to receive(:notify)
      end

      it "logs the error" do
        processor.process(message)

        expect(logger).to have_received(:error).with(<<~MSG)
          Failed to process incoming document message:
          RuntimeError: Could not process
          Message content: {:\"I am\"=>\"a message\"}
        MSG
      end

      it "sends the error to Sentry" do
        processor.process(message)

        expect(GovukError).to have_received(:notify).with(error)
      end

      it "rejects the message" do
        processor.process(message)

        expect(message).not_to be_acked
        expect(message).to be_discarded
      end
    end

    context "when synchronising the document fails" do
      let(:error) { RuntimeError.new("Could not synchronize") }

      before do
        allow(document).to receive(:synchronize).and_raise(error)
      end

      it "logs the error" do
        processor.process(message)

        expect(logger).to have_received(:error).with(<<~MSG)
          Failed to process incoming document message:
          RuntimeError: Could not synchronize
          Message content: {:\"I am\"=>\"a message\"}
        MSG
      end

      it "sends the error to Sentry" do
        processor.process(message)

        expect(GovukError).to have_received(:notify).with(error)
      end

      it "rejects the message" do
        processor.process(message)

        expect(message).not_to be_acked
        expect(message).to be_discarded
      end
    end
  end
end
