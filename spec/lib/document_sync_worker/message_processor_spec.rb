require "govuk_message_queue_consumer/test_helpers"

RSpec.describe DocumentSyncWorker::MessageProcessor do
  subject(:processor) { described_class.new(repository:) }

  let(:repository) { double }
  let(:document) { double(synchronize_to: nil) } # rubocop:disable RSpec/VerifiedDoubles (interface)

  it_behaves_like "a message queue processor"

  describe "when receiving an incoming message" do
    let(:message) { GovukMessageQueueConsumer::MockMessage.new(payload) }
    let(:payload) { { "I am" => "a message" } }

    before do
      allow(Rails.logger).to receive(:info)
      allow(DocumentSyncWorker::Document).to receive(:for).with(payload).and_return(document)
    end

    it "acks incoming messages" do
      processor.process(message)

      expect(message).to be_acked
    end

    it "makes the document synchronize itself to the repository" do
      processor.process(message)

      expect(document).to have_received(:synchronize_to).with(repository)
    end

    context "when creating the document fails" do
      let(:logger) { instance_double(Logger, error: nil) }
      let(:error) { RuntimeError.new("Something went wrong") }

      before do
        allow(DocumentSyncWorker::Document).to receive(:for).and_raise(error)
        allow(DocumentSyncWorker).to receive(:logger).and_return(logger)
        allow(GovukError).to receive(:notify)
      end

      it "logs the error" do
        processor.process(message)

        expect(logger).to have_received(:error).with(<<~MSG)
          Failed to process incoming document message:
          RuntimeError: Something went wrong
          Message content: {\"I am\"=>\"a message\"}
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
