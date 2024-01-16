require "govuk_message_queue_consumer/test_helpers"

RSpec.describe "Document synchronization" do
  let(:message) { GovukMessageQueueConsumer::MockMessage.new(payload) }

  let(:put_service) { instance_double(DiscoveryEngine::Sync::Put, call: nil) }
  let(:delete_service) { instance_double(DiscoveryEngine::Sync::Delete, call: nil) }

  before do
    allow(DiscoveryEngine::Sync::Put).to receive(:new).and_return(put_service)
    allow(DiscoveryEngine::Sync::Delete).to receive(:new).and_return(delete_service)

    Timecop.freeze(Time.zone.local(1989, 12, 13, 1, 2, 3)) do
      PublishingApiMessageProcessor.new.process(message)
    end
  end

  describe "for a 'press_release' message" do
    let(:payload) { json_fixture_as_hash("message_queue/press_release_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "5941cb22-5d52-4212-83b6-255d75d2c680",
        {
          content_id: "5941cb22-5d52-4212-83b6-255d75d2c680",
          title: "UK and Japan strengthen cooperation in the area of digital government",
          description: "On Monday 31 October 2022, the UK and Japan signed a Memorandum of Cooperation (MoC) to deepen ties on digital government transformation.",
          link: "/government/news/uk-and-japan-strengthen-cooperation-in-the-area-of-digital-government",
          url: "https://www.gov.uk/government/news/uk-and-japan-strengthen-cooperation-in-the-area-of-digital-government",
          public_timestamp: 1_667_217_614,
          document_type: "press_release",
          is_historic: 0,
          government_name: "2015 Conservative government",
          content_purpose_supergroup: "news_and_communications",
          part_of_taxonomy_tree: %w[37d0fa26-abed-4c74-8835-b3b51ae1c8b2],
          organisations: %w[government-digital-service],
          locale: "en",
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 12_345,
          },
        },
        content: a_string_including("<div class=\"govspeak\"><p>The UK was represented remotely"),
        payload_version: 12_345,
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
          url: "https://www.gov.uk/foreign-travel-advice/austria",
          public_timestamp: 1_697_629_071,
          document_type: "travel_advice",
          is_historic: 0,
          content_purpose_supergroup: "guidance_and_regulation",
          part_of_taxonomy_tree: %w[
            8f78544f-a4ed-46b4-8163-889679d119b9 71cd9f51-f492-4c3f-91ca-5ad694c26592
          ],
          organisations: %w[foreign-commonwealth-development-office],
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
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 12_345,
          },
        },
        content: a_string_including("<h1>Warnings and insurance</h1>\n<p>The Foreign"),
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
          url: "https://www.gov.uk/government/news/travel-advice-for-fans-going-to-champions-league-and-europa-league-matches-this-week",
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
          organisations: %w[foreign-commonwealth-office],
          locale: "en",
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 12_345,
          },
        },
        content: a_string_including("<div class=\"govspeak\"><p>In the UEFA Champions"),
        payload_version: 12_345,
      )
    end
  end

  describe "for a 'manual_section' message" do
    let(:payload) { json_fixture_as_hash("message_queue/manual_section_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "e1f47495-b58d-41ca-84bb-ccb2b751cc3f",
        {
          content_id: "e1f47495-b58d-41ca-84bb-ccb2b751cc3f",
          title: "6. Body, structure and attachments",
          description: "Structure and attachments (including exhaust system and bumpers), and body and interior (including doors and catches, seats and floor) rules and inspection for car and passenger vehicle MOT tests.",
          link: "/guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/6-body-structure-and-attachments",
          url: "https://www.gov.uk/guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/6-body-structure-and-attachments",
          public_timestamp: 1_646_221_134,
          document_type: "manual_section",
          is_historic: 0,
          content_purpose_supergroup: "guidance_and_regulation",
          organisations: %w[driver-and-vehicle-standards-agency],
          manual: "/guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles",
          locale: "en",
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 12_345,
          },
        },
        content: a_string_matching(/<h2 id="section-6-1">6\.1\. Structure.+<\/table>\n\n/m),
        payload_version: 12_345,
      )
    end
  end

  describe "for a 'service_manual_guide' message" do
    let(:payload) { json_fixture_as_hash("message_queue/service_manual_guide_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "174c41e0-3316-4e9d-be46-6555d52f3cb7",
        {
          content_id: "174c41e0-3316-4e9d-be46-6555d52f3cb7",
          title: "5. Make sure everyone can use the service",
          description: "Provide a service that everyone can use, including disabled people and people with other legally protected characteristics. And people who do not have access to the internet or lack the skills or confidence to use it.",
          link: "/service-manual/service-standard/point-5-make-sure-everyone-can-use-the-service",
          url: "https://www.gov.uk/service-manual/service-standard/point-5-make-sure-everyone-can-use-the-service",
          public_timestamp: 1_653_906_028,
          document_type: "service_manual_guide",
          is_historic: 0,
          content_purpose_supergroup: "other",
          organisations: %w[government-digital-service],
          manual: "/service-manual",
          locale: "en",
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 1989,
          },
        },
        content: a_string_matching(/Make sure everyone can use the service/),
        payload_version: 1989,
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
          link: "/government/organisations/legal-aid-agency",
          url: "https://www.gov.uk/government/organisations/legal-aid-agency",
          public_timestamp: 1_695_391_634,
          document_type: "organisation",
          is_historic: 0,
          organisation_state: "live",
          content_purpose_supergroup: "other",
          organisations: %w[legal-aid-agency],
          locale: "en",
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 12_345,
          },
        },
        content: a_string_including("LAA\n<div class=\"govspeak\"><p>We provide civil"),
        payload_version: 12_345,
      )
    end
  end

  describe "for an 'worldwide_organisation' message" do
    let(:payload) { json_fixture_as_hash("message_queue/worldwide_organisation_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "f4c394f9-7a30-11e4-a3cb-005056011aef",
        {
          content_id: "f4c394f9-7a30-11e4-a3cb-005056011aef",
          title: "British Embassy Vienna",
          description: "The British Embassy in Vienna maintains and develops relations between the UK and Austria.",
          link: "/world/organisations/british-embassy-vienna",
          url: "https://www.gov.uk/world/organisations/british-embassy-vienna",
          public_timestamp: 1_372_436_926,
          document_type: "worldwide_organisation",
          is_historic: 0,
          part_of_taxonomy_tree: %w[
            f1744c25-bbae-42d5-b0fa-452ccea8f802
            ca97c97d-30c3-4c31-86d5-a84fb37f919a
          ],
          world_locations: %w[austria],
          content_purpose_supergroup: "other",
          locale: "en",
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 12_345,
          },
        },
        content: a_string_including("maintains and develops relations between the UK and Austria"),
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
          link: "/government/publications/directgov-2010-and-beyond-revolution-not-evolution-a-report-by-martha-lane-fox",
          url: "https://www.gov.uk/government/publications/directgov-2010-and-beyond-revolution-not-evolution-a-report-by-martha-lane-fox",
          public_timestamp: 1_290_470_400,
          document_type: "independent_report",
          is_historic: 0,
          government_name: "2010 to 2015 Conservative and Liberal Democrat coalition government",
          content_purpose_supergroup: "research_and_statistics",
          part_of_taxonomy_tree: %w[f3caf326-fe33-410f-b7f4-553f4011c81e],
          organisations: %w[cabinet-office efficiency-and-reform-group government-digital-service],
          locale: "en",
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 54_321,
          },
        },
        content: a_string_including(<<~TEXT.chomp),
          Directgov 2010 and beyond: revolution not evolution, a report by Martha Lane Fox
          A report from the Digital Champion Martha Lane Fox with recommendations for the future of Directgov.
          Directgov 2010 and Beyond: Revolution Not Evolution - Letter from Martha Lane Fox to Francis Maude
          Francis Maude's reply to Martha Lane Fox's letter
          Directgov Strategic Review - Executive Summary
          <div class=\"govspeak\"><p>A report from the Digital
        TEXT
        payload_version: 54_321,
      )
    end
  end

  describe "for a 'guidance' message with attachments" do
    let(:payload) { json_fixture_as_hash("message_queue/guidance_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "5d60fe55-7631-11e4-a3cb-005056011aef",
        {
          content_id: "5d60fe55-7631-11e4-a3cb-005056011aef",
          content_purpose_supergroup: "guidance_and_regulation",
          description: "How the Equality Act 2010 defines disability, and what law changes mean for the public, businesses, and the public and voluntary sectors.",
          document_type: "guidance",
          government_name: "2010 to 2015 Conservative and Liberal Democrat coalition government",
          is_historic: 0,
          link: "/government/publications/equality-act-guidance",
          locale: "en",
          organisations: %w[government-equalities-office],
          part_of_taxonomy_tree: %w[
            7acd1cbd-2f79-44f9-9ca5-2d12637a77ad
            75efcbd0-4f01-4ce2-b151-01a58f8fb7a9
          ],
          public_timestamp: 1_362_743_145,
          title: "Equality Act 2010: how it might affect you",
          url: "https://www.gov.uk/government/publications/equality-act-guidance",
          parts: [
            {
              title: "Disability: Equality Act 2010 - Guidance on matters to be taken into account in determining questions relating to the definition of disability (HTML)",
              body: "",
              slug: "disability-equality-act-2010-guidance-on-matters-to-be-taken-into-account-in-determining-questions-relating-to-the-definition-of-disability-html",
            },
            {
              title: "Individuals: a summary guide to your rights (HTML)",
              body: "",
              slug: "individuals-a-summary-guide-to-your-rights-html",
            },
            {
              title: "Disability: quick start guide for service providers (HTML)",
              body: "",
              slug: "disability-quick-start-guide-for-service-providers-html",
            },
          ],
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 12_345,
          },
        },
        content: a_string_starting_with("Equality Act 2010: how it might affect you"),
        payload_version: 12_345,
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
          url: "https://www.gov.uk/world/switzerland",
          public_timestamp: 1_583_165_036,
          document_type: "taxon",
          is_historic: 0,
          content_purpose_supergroup: "other",
          locale: "en",
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 12_345,
          },
        },
        content: <<~TEXT.chomp,
          UK help and services in Switzerland
          Services if you're visiting, studying, working or living in Switzerland. Includes information about trading with and doing business in the UK and Switzerland, and your rights after the UK’s exit from the EU.
        TEXT
        payload_version: 12_345,
      )
    end
  end

  describe "for a 'speech' message" do
    let(:payload) { json_fixture_as_hash("message_queue/speech_message.json") }

    it "is added to Discovery Engine through the Put service" do
      expect(put_service).to have_received(:call).with(
        "5fac6be0-146e-40ea-a899-c3299f62eff9",
        {
          content_id: "5fac6be0-146e-40ea-a899-c3299f62eff9",
          title: "Service of thanksgiving for the life of Her Majesty Queen Elizabeth II at the Washington National Cathedral",
          description: "British Ambassador to the USA Dame Karen Pierce DCMG, spoke at the service of thanksgiving for the life of Her Majesty Queen Elizabeth II.",
          link: "/government/speeches/a-service-of-thanksgiving-for-the-life-of-her-majesty-queen-elizabeth-ii-at-the-washington-national-cathedral",
          url: "https://www.gov.uk/government/speeches/a-service-of-thanksgiving-for-the-life-of-her-majesty-queen-elizabeth-ii-at-the-washington-national-cathedral",
          public_timestamp: 1_663_794_900,
          government_name: "2015 Conservative government",
          organisations: %w[foreign-commonwealth-development-office],
          document_type: "speech",
          is_historic: 0,
          part_of_taxonomy_tree: %w[d6dba75a-42bd-4e1e-984c-2bddb6b41951],
          world_locations: %w[usa],
          topical_events: %w[her-majesty-queen-elizabeth-ii],
          content_purpose_supergroup: "news_and_communications",
          locale: "en",
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 12_345,
          },
        },
        content: a_string_including("Service of thanksgiving for the life of Her Majesty Queen Elizabeth II"),
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
          link: "https://www.brighton-hove.gov.uk",
          url: "https://www.brighton-hove.gov.uk",
          public_timestamp: 1_695_912_979,
          document_type: "external_content",
          is_historic: 0,
          content_purpose_supergroup: "other",
          locale: "en",
          debug: {
            last_synced_at: "1989-12-13T01:02:03+00:00",
            payload_version: 17,
          },
        },
        content: a_string_including("Brighton & Hove City Council"),
        payload_version: 17,
      )
    end
  end

  describe "for a non-English 'worldwide_organisation' message" do
    let(:payload) { json_fixture_as_hash("message_queue/non_english_worldwide_organisation_message.json") }

    it "is skipped completely and not deleted" do
      expect(delete_service).not_to have_received(:call)
    end
  end

  describe "for a withdrawn 'notice' message" do
    let(:payload) { json_fixture_as_hash("message_queue/withdrawn_notice_message.json") }

    it "is proactively deleted from Discovery Engine through the Delete service" do
      expect(delete_service).to have_received(:call).with(
        "e3b7c15d-1928-4101-9912-c9b40a6d6e78",
        payload_version: 12_345,
      )
    end
  end

  describe "for an 'html_publication' message" do
    let(:payload) { json_fixture_as_hash("message_queue/html_publication_message.json") }

    it "is proactively deleted from Discovery Engine through the Delete service" do
      expect(delete_service).to have_received(:call).with(
        "1f1f2c96-5a14-4d2a-9d0c-be6ac6c62c3b",
        payload_version: 12_345,
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
