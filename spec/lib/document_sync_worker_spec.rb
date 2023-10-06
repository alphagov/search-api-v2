require "govuk_message_queue_consumer"

RSpec.describe DocumentSyncWorker do
  describe ".run" do
    let(:consumer) { instance_double(GovukMessageQueueConsumer::Consumer, run: nil) }
    let(:repository) { double }

    before do
      described_class.configure do |config|
        config.message_queue_name = "test-queue"
        config.repository = repository
      end

      allow(GovukMessageQueueConsumer::Consumer).to receive(:new).with(
        queue_name: "test-queue",
        processor: an_instance_of(DocumentSyncWorker::MessageProcessor),
      ).and_return(consumer)
    end

    it "runs our processor through govuk_message_queue_consumer" do
      described_class.run

      expect(consumer).to have_received(:run)
    end
  end
end
