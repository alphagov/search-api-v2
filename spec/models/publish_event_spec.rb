RSpec.describe PublishEvent do
  describe ".from_message_hash" do
    subject(:publish_event) { described_class.from_message_hash(message_hash) }

    context "with a valid message hash" do
      let(:message_hash) { json_fixture_as_hash("message_queue/message.json") }

      it "maps the message onto a PublishEvent" do
        expected_document = Document.new(
          content_id: "f75d26a3-25a4-4c31-beea-a77cada4ce12",
          title: "Ebola medal for over 3000 heroes",
        )
        expected_publish_event = described_class.new(
          update_type: "republish",
          payload_version: 65_861_808,
          document: expected_document,
        )

        expect(publish_event).to eq(expected_publish_event)
      end
    end

    context "with a message hash missing required fields" do
      let(:message_hash) { { "title" => "I'm incomplete" } }

      it "raises an error" do
        expect { publish_event }.to raise_error(KeyError)
      end
    end
  end
end
