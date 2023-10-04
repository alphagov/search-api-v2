require "govuk_message_queue_consumer"
require "govuk_message_queue_consumer/test_helpers"

RSpec.describe "Publishing event pipeline" do
  let(:repository) { PublishingEventPipeline::Repositories::TestRepository.new(documents) }
  let(:message) { GovukMessageQueueConsumer::MockMessage.new(payload) }

  before do
    PublishingEventPipeline::MessageProcessor.new(repository:).process(message)
  end

  describe "for a 'press_release' message" do
    let(:documents) { {} }
    let(:payload) { json_fixture_as_hash("message_queue/press_release_message.json") }

    it "is added to the repository" do
      result = repository.get("f75d26a3-25a4-4c31-beea-a77cada4ce12")
      expect(result[:metadata]).to eq(
        title: "Ebola medal for over 3000 heroes",
        description: "A new medal has been created to recognise the bravery and hard work of people who have helped to stop the spread of Ebola.",
        link: "/government/news/ebola-medal-for-over-3000-heroes",
      )
      expect(result[:content]).to start_with("<div class=\"govspeak\"><p>The government has")
      expect(result[:content]).to end_with("response to Ebola</a>.</p>\n</div>\n\n</div>")
      expect(result[:content].length).to eq(4_932)
    end
  end

  describe "for an 'external_content' message" do
    let(:documents) { {} }
    let(:payload) { json_fixture_as_hash("message_queue/external_content_message.json") }

    it "is added to the repository" do
      result = repository.get("526d5caf-221b-4c7b-9e74-b3e0b189fc8d")
      expect(result[:metadata]).to eq(
        title: "Brighton & Hove City Council",
        description: "Website of Brighton & Hove City Council",
        link: "https://www.brighton-hove.gov.uk",
      )
      expect(result[:content]).to eq("Brighton & Hove City Council")
    end
  end

  describe "for a 'gone' message" do
    let(:documents) { { "966bae6d-223e-4102-a6e5-e874012390e5" => double } }
    let(:payload) { json_fixture_as_hash("message_queue/gone_message.json") }

    it "is removed from the repository" do
      result = repository.get("966bae6d-223e-4102-a6e5-e874012390e5")
      expect(result).to be_nil
    end
  end
end
