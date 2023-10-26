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

      expect(result[:metadata]).to match_json_schema(metadata_json_schema)
      expect(result[:metadata]).to eq(
        content_id: "f75d26a3-25a4-4c31-beea-a77cada4ce12",
        title: "Ebola medal for over 3000 heroes",
        description: "A new medal has been created to recognise the bravery and hard work of people who have helped to stop the spread of Ebola.",
        additional_searchable_text: "",
        link: "/government/news/ebola-medal-for-over-3000-heroes",
        url: "http://www.dev.gov.uk/government/news/ebola-medal-for-over-3000-heroes",
        public_timestamp: 1_434_021_240,
        document_type: "press_release",
        is_historic: 0,
        government_name: "2015 Conservative government",
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

  describe "for a 'travel_advice' message" do
    let(:documents) { {} }
    let(:payload) { json_fixture_as_hash("message_queue/travel_advice_message.json") }

    it "is added to the repository" do
      result = repository.get("b662d0a3-c20d-4167-8056-b9c7d058d860")

      expect(result[:metadata]).to match_json_schema(metadata_json_schema)
      expect(result[:metadata]).to eq(
        content_id: "b662d0a3-c20d-4167-8056-b9c7d058d860",
        title: "Austria travel advice",
        description: "FCDO travel advice for Austria. Includes safety and security, insurance, entry requirements and legal differences.",
        additional_searchable_text: "",
        link: "/foreign-travel-advice/austria",
        url: "http://www.dev.gov.uk/foreign-travel-advice/austria",
        public_timestamp: 1_697_629_071,
        document_type: "travel_advice",
        is_historic: 0,
        content_purpose_supergroup: "guidance_and_regulation",
        part_of_taxonomy_tree: %w[
          8f78544f-a4ed-46b4-8163-889679d119b9 71cd9f51-f492-4c3f-91ca-5ad694c26592
        ],
        locale: "en",
        parts: [
          {
            slug: "warnings-and-insurance",
            title: "Warnings and insurance",
            body: "The Foreign, Commonwealth & Development Office (FCDO) provides advice…",
          },
          {
            slug: "entry-requirements",
            title: "Entry requirements",
            body: "This advice reflects the UK government’s understanding of current rules…",
          },
          {
            slug: "safety-and-security",
            title: "Safety and security",
            body: "Terrorism There is a high threat of terrorist attack globally affecting UK…",
          },
          {
            slug: "health",
            title: "Health",
            body: "Before you travel check that: your destination can provide the healthcare…",
          },
          {
            slug: "getting-help",
            title: "Getting help",
            body: "The Foreign, Commonwealth & Development Office (FCDO) cannot provide…",
          },
        ],
      )

      expect(result[:content]).to include("<h1>Warnings and insurance</h1>\n<p>The Foreign,")
      expect(result[:content]).to include("<h1>Entry requirements</h1>\n<p>This advice reflects")
      expect(result[:content]).to include("<h1>Safety and security</h1>\n<h2 id=\"terrorism\">")
      expect(result[:content]).to include("<h1>Health</h1>\n<p>Before you travel")
      expect(result[:content]).to include("<h1>Getting help</h1>\n<p>The Foreign,")
    end
  end

  describe "for a historic 'news_story' message" do
    let(:documents) { {} }
    let(:payload) { json_fixture_as_hash("message_queue/historic_news_story_message.json") }

    it "is added to the repository" do
      result = repository.get("5c880596-7631-11e4-a3cb-005056011aef")

      expect(result[:metadata]).to match_json_schema(metadata_json_schema)
      expect(result[:metadata]).to eq(
        content_id: "5c880596-7631-11e4-a3cb-005056011aef",
        title: "Travel advice for fans going to Champions League and Europa League matches this week",
        description: "Tottenham, Manchester City and Chelsea are playing matches in Europe this week. If you’re going to the matches, check our travel advice for fans.",
        additional_searchable_text: "",
        link: "/government/news/travel-advice-for-fans-going-to-champions-league-and-europa-league-matches-this-week",
        url: "http://www.dev.gov.uk/government/news/travel-advice-for-fans-going-to-champions-league-and-europa-league-matches-this-week",
        public_timestamp: 1_284_336_000,
        document_type: "news_story",
        is_historic: 1,
        government_name: "2010 to 2015 Conservative and Liberal Democrat coalition government",
        content_purpose_supergroup: "news_and_communications",
        part_of_taxonomy_tree: %w[
          06ad07f7-1e79-462f-a192-6b2c9d92089c
          ce9e9802-6138-4fe9-9f33-045ef213be29
          3dbeb4a3-33c0-4bda-bd21-b721b0f8736f
        ],
        locale: "en",
      )

      expect(result[:content]).to start_with("<div class=\"govspeak\"><p>In the UEFA Champions")
      expect(result[:content]).to end_with("football fans</a>.</p>\n</div>")
      expect(result[:content].length).to eq(2_118)
    end
  end

  describe "for an 'organisation' message" do
    let(:documents) { {} }
    let(:payload) { json_fixture_as_hash("message_queue/organisation_message.json") }

    it "is added to the repository" do
      result = repository.get("6ba90ae6-972d-4d48-ad66-693bbb31496d")

      expect(result[:metadata]).to match_json_schema(metadata_json_schema)
      expect(result[:metadata]).to eq(
        content_id: "6ba90ae6-972d-4d48-ad66-693bbb31496d",
        title: "Legal Aid Agency",
        description: "We provide civil and criminal legal aid and advice in England and Wales to help people deal with their legal problems. LAA is an executive agency, sponsored by the Ministry of Justice .",
        additional_searchable_text: "",
        link: "/government/organisations/legal-aid-agency",
        url: "http://www.dev.gov.uk/government/organisations/legal-aid-agency",
        public_timestamp: 1_695_391_634,
        document_type: "organisation",
        is_historic: 0,
        organisation_state: "live",
        content_purpose_supergroup: "other",
        part_of_taxonomy_tree: [],
        locale: "en",
      )

      expect(result[:content]).to start_with("<div class=\"govspeak\"><p>We provide civil")
      expect(result[:content]).to end_with("Ministry of Justice</a>.</p>\n</div>")
      expect(result[:content].length).to eq(345)
    end
  end

  describe "for an 'external_content' message" do
    let(:documents) { {} }
    let(:payload) { json_fixture_as_hash("message_queue/external_content_message.json") }

    it "is added to the repository" do
      result = repository.get("526d5caf-221b-4c7b-9e74-b3e0b189fc8d")

      expect(result[:metadata]).to match_json_schema(metadata_json_schema)
      expect(result[:metadata]).to eq(
        content_id: "526d5caf-221b-4c7b-9e74-b3e0b189fc8d",
        title: "Brighton & Hove City Council",
        description: "Website of Brighton & Hove City Council",
        additional_searchable_text: "Brighton & Hove City Council",
        link: "https://www.brighton-hove.gov.uk",
        url: "https://www.brighton-hove.gov.uk",
        public_timestamp: 1_695_912_979,
        document_type: "external_content",
        is_historic: 0,
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
