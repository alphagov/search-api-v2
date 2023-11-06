require "govuk_message_queue_consumer/test_helpers"

RSpec.describe "Document synchronization" do
  let(:message) { GovukMessageQueueConsumer::MockMessage.new(payload) }

  let(:put_service) { instance_double(DiscoveryEngine::Put, call: nil) }
  let(:delete_service) { instance_double(DiscoveryEngine::Put, call: nil) }

  before do
    allow(DiscoveryEngine::Put).to receive(:new).and_return(put_service)
    allow(DiscoveryEngine::Delete).to receive(:new).and_return(delete_service)

    PublishingApiMessageProcessor.new.process(message)
  end

  describe "for a 'press_release' message" do
    let(:payload) { json_fixture_as_hash("message_queue/press_release_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "f75d26a3-25a4-4c31-beea-a77cada4ce12",
        {
          content_id: "f75d26a3-25a4-4c31-beea-a77cada4ce12",
          title: "Ebola medal for over 3000 heroes",
          description: "A new medal has been created to recognise the bravery and hard work of people who have helped to stop the spread of Ebola.",
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
        },
        content: a_string_starting_with("<div class=\"govspeak\"><p>The government has today"),
        payload_version: 65_861_808,
      )
    end
  end

  describe "for a 'travel_advice' message" do
    let(:payload) { json_fixture_as_hash("message_queue/travel_advice_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "b662d0a3-c20d-4167-8056-b9c7d058d860",
        {
          content_id: "b662d0a3-c20d-4167-8056-b9c7d058d860",
          title: "Austria travel advice",
          description: "FCDO travel advice for Austria. Includes safety and security, insurance, entry requirements and legal differences.",
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
        },
        content: a_string_starting_with("<h1>Warnings and insurance</h1>\n<p>The Foreign"),
        payload_version: 12_345,
      )
    end
  end

  describe "for a historic 'news_story' message" do
    let(:payload) { json_fixture_as_hash("message_queue/historic_news_story_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "5c880596-7631-11e4-a3cb-005056011aef",
        {
          content_id: "5c880596-7631-11e4-a3cb-005056011aef",
          title: "Travel advice for fans going to Champions League and Europa League matches this week",
          description: "Tottenham, Manchester City and Chelsea are playing matches in Europe this week. If you’re going to the matches, check our travel advice for fans.",
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
        },
        content: a_string_starting_with("<div class=\"govspeak\"><p>In the UEFA Champions"),
        payload_version: 12_345,
      )
    end
  end

  describe "for an 'organisation' message" do
    let(:payload) { json_fixture_as_hash("message_queue/organisation_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "6ba90ae6-972d-4d48-ad66-693bbb31496d",
        {
          content_id: "6ba90ae6-972d-4d48-ad66-693bbb31496d",
          title: "Legal Aid Agency",
          description: "We provide civil and criminal legal aid and advice in England and Wales to help people deal with their legal problems. LAA is an executive agency, sponsored by the Ministry of Justice .",
          additional_searchable_text: "LAA",
          link: "/government/organisations/legal-aid-agency",
          url: "http://www.dev.gov.uk/government/organisations/legal-aid-agency",
          public_timestamp: 1_695_391_634,
          document_type: "organisation",
          is_historic: 0,
          organisation_state: "live",
          content_purpose_supergroup: "other",
          locale: "en",
        },
        content: a_string_starting_with("<div class=\"govspeak\"><p>We provide civil"),
        payload_version: 12_345,
      )
    end
  end

  describe "for an 'independent_report' message" do
    let(:payload) { json_fixture_as_hash("message_queue/independent_report_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "5d315ee8-7631-11e4-a3cb-005056011aef",
        {
          content_id: "5d315ee8-7631-11e4-a3cb-005056011aef",
          title: "Directgov 2010 and beyond: revolution not evolution, a report by Martha Lane Fox",
          description: "A report from the Digital Champion Martha Lane Fox with recommendations for the future of Directgov.",
          additional_searchable_text: <<~TEXT.chomp,
            Directgov 2010 and Beyond: Revolution Not Evolution - Letter from Martha Lane Fox to Francis Maude
            Francis Maude's reply to Martha Lane Fox's letter
            Directgov Strategic Review - Executive Summary
          TEXT
          link: "/government/publications/directgov-2010-and-beyond-revolution-not-evolution-a-report-by-martha-lane-fox",
          url: "http://www.dev.gov.uk/government/publications/directgov-2010-and-beyond-revolution-not-evolution-a-report-by-martha-lane-fox",
          public_timestamp: 1_290_470_400,
          document_type: "independent_report",
          is_historic: 0,
          government_name: "2010 to 2015 Conservative and Liberal Democrat coalition government",
          content_purpose_supergroup: "research_and_statistics",
          part_of_taxonomy_tree: %w[f3caf326-fe33-410f-b7f4-553f4011c81e],
          locale: "en",
        },
        content: a_string_starting_with("<div class=\"govspeak\"><p>A report from the Digital"),
        payload_version: 54_321,
      )
    end
  end

  describe "for a 'taxon' message that isn't ignorelisted" do
    let(:payload) { json_fixture_as_hash("message_queue/world_taxon_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "f1724368-504f-4b3c-9dc2-41121046de9f",
        {
          content_id: "f1724368-504f-4b3c-9dc2-41121046de9f",
          title: "UK help and services in Switzerland",
          description: "Services if you're visiting, studying, working or living in Switzerland. Includes information about trading with and doing business in the UK and Switzerland, and your rights after the UK’s exit from the EU.",
          link: "/world/switzerland",
          url: "http://www.dev.gov.uk/world/switzerland",
          public_timestamp: 1_583_165_036,
          document_type: "taxon",
          is_historic: 0,
          content_purpose_supergroup: "other",
          locale: "en",
        },
        content: "",
        payload_version: 12_345,
      )
    end
  end

  describe "for an 'external_content' message" do
    let(:payload) { json_fixture_as_hash("message_queue/external_content_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "526d5caf-221b-4c7b-9e74-b3e0b189fc8d",
        {
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
          locale: "en",
        },
        content: "",
        payload_version: 17,
      )
    end
  end

  describe "for a 'gone' message" do
    let(:payload) { json_fixture_as_hash("message_queue/gone_message.json") }

    it "is deleted from Discovery Engine through the Delete service" do
      expect(delete_service).to have_received(:call).with(
        "966bae6d-223e-4102-a6e5-e874012390e5",
        payload_version: 65_893_230,
      )
    end
  end
end
