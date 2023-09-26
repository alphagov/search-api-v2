require "govuk_message_queue_consumer"

RSpec.describe "Publishing event pipeline" do
  let(:repository) { PublishingEventPipeline::Repositories::TestRepository.new(documents) }
  let(:message) { GovukMessageQueueConsumer::MockMessage.new(payload) }

  before do
    PublishingEventPipeline.configure do |config|
      config.repository = repository
    end

    PublishingEventPipeline::MessageProcessor.new.process(message)
  end

  describe "when a message is received that a document is published" do
    let(:documents) { {} }
    let(:payload) { json_fixture_as_hash("message_queue/republish_message.json") }

    it "is added to the repository" do
      result = repository.get("f75d26a3-25a4-4c31-beea-a77cada4ce12")
      # TODO: Flesh out the document model and test that it is as expected
      expect(result).to be_present
    end
  end

  describe "when a message is received that a document is unpublished" do
    let(:documents) { { "966bae6d-223e-4102-a6e5-e874012390e5" => double } }
    let(:payload) { json_fixture_as_hash("message_queue/gone_message.json") }

    it "is removed from the repository" do
      result = repository.get("966bae6d-223e-4102-a6e5-e874012390e5")
      # TODO: Flesh out the document model and test that it is as expected
      expect(result).to be_nil
    end
  end
end
