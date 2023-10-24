require "govuk_message_queue_consumer/test_helpers"

RSpec.describe "Document sync worker end-to-end" do
  let(:repository) { DocumentSyncWorker::Repositories::TestRepository.new(documents) }
  let(:message) { GovukMessageQueueConsumer::MockMessage.new(payload) }

  before do
    DocumentSyncWorker::MessageProcessor.new(repository:).process(message)
  end

  describe "for a 'press_release' message" do
    let(:documents) { {} }
    let(:payload) { json_fixture_as_hash("message_queue/press_release_message.json") }

    it "is added to the repository" do
      result = repository.get("f75d26a3-25a4-4c31-beea-a77cada4ce12")
      expect(result[:metadata]).to eq(
        content_id: "f75d26a3-25a4-4c31-beea-a77cada4ce12",
        title: "Ebola medal for over 3000 heroes",
        description: "A new medal has been created to recognise the bravery and hard work of people who have helped to stop the spread of Ebola.",
        additional_searchable_text: "",
        link: "/government/news/ebola-medal-for-over-3000-heroes",
        url: "http://www.dev.gov.uk/government/news/ebola-medal-for-over-3000-heroes",
        public_timestamp: 1_434_021_240,
        document_type: "press_release",
        content_purpose_supergroup: "news_and_communications",
        part_of_taxonomy_tree: %w[
          668cd623-c7a8-4159-9575-90caac36d4b4 c31256e8-f328-462b-993f-dce50b7892e9
        ],
        locale: "en",
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
        content_id: "526d5caf-221b-4c7b-9e74-b3e0b189fc8d",
        title: "Brighton & Hove City Council",
        description: "Website of Brighton & Hove City Council",
        additional_searchable_text: "Brighton & Hove City Council",
        link: "https://www.brighton-hove.gov.uk",
        url: "https://www.brighton-hove.gov.uk",
        public_timestamp: 1_695_912_979,
        document_type: "external_content",
        content_purpose_supergroup: "other",
        part_of_taxonomy_tree: [],
        locale: "en",
      )
      expect(result[:content]).to be_blank
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
