require "publishing_event_pipeline/publishing_event"

RSpec.describe PublishingEventPipeline::PublishingEvent do
  describe ".from_message_hash" do
    subject(:publishing_event) { described_class.from_message_hash(message_hash) }

    context "with a valid republish message" do
      let(:message_hash) { json_fixture_as_hash("message_queue/republish_message.json") }

      it "maps the message onto a PublishingEvent" do
        expected_document = SearchableDocumentData.new(
          content_id: "f75d26a3-25a4-4c31-beea-a77cada4ce12",
          title: "Ebola medal for over 3000 heroes",
        )
        expected_publishing_event = described_class.new(
          update_type: "republish",
          payload_version: 65_861_808,
          document: expected_document,
        )

        expect(publishing_event).to eq(expected_publishing_event)
      end
    end

    context "with a valid gone message" do
      let(:message_hash) { json_fixture_as_hash("message_queue/gone_message.json") }

      it "maps the message onto a PublishingEvent" do
        expected_document = SearchableDocumentData.new(
          content_id: "966bae6d-223e-4102-a6e5-e874012390e5",
          title: nil,
        )
        expected_publishing_event = described_class.new(
          update_type: nil,
          payload_version: 65_893_230,
          document: expected_document,
        )

        expect(publishing_event).to eq(expected_publishing_event)
      end
    end

    context "with a message hash missing required fields" do
      let(:message_hash) { { "title" => "I'm incomplete" } }

      it "raises an error" do
        expect { publishing_event }.to raise_error(KeyError)
      end
    end
  end
end
