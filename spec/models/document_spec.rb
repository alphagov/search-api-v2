RSpec.describe Document do
  describe ".from_message_hash" do
    subject(:document) { described_class.from_message_hash(message_hash) }

    context "with a valid message hash" do
      let(:message_hash) { json_fixture_as_hash("message_queue/message.json") }

      it "maps the message onto a Document" do
        expected_document = described_class.new(
          content_id: "f75d26a3-25a4-4c31-beea-a77cada4ce12",
          title: "Ebola medal for over 3000 heroes",
        )

        expect(document).to eq(expected_document)
      end
    end

    context "with a message hash missing a content ID" do
      let(:message_hash) { { "title" => "I'm incomplete" } }

      it "raises an error" do
        expect { document }.to raise_error(KeyError)
      end
    end
  end
end
