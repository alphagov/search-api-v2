RSpec.describe PublishingEventPipeline::DocumentLifecycleEvent do
  subject(:event) { described_class.new(message_hash) }

  describe "#initialize" do
    context "with a valid republish message" do
      let(:message_hash) { json_fixture_as_hash("message_queue/republish_message.json") }

      it "initializes without error" do
        expect { event }.not_to raise_error
      end
    end

    context "with a valid gone message" do
      let(:message_hash) { json_fixture_as_hash("message_queue/gone_message.json") }

      it "initializes without error" do
        expect { event }.not_to raise_error
      end
    end

    context "with an invalid message" do
      let(:message_hash) { { "title" => "I'm incomplete" } }

      it "raises an error on initialization" do
        expect { event }.to raise_error(KeyError)
      end
    end
  end

  describe "#synchronize_to" do
    let(:repository) do
      double( # rubocop:disable RSpec/VerifiedDoubles (this is an interface)
        "Repository",
        put: nil,
        delete: nil,
      )
    end

    context "when document_type indicates delete" do
      let(:message_hash) { json_fixture_as_hash("message_queue/gone_message.json") }

      it "calls delete on the repository" do
        event.synchronize_to(repository)

        expect(repository).to have_received(:delete).with(
          "966bae6d-223e-4102-a6e5-e874012390e5",
          payload_version: 65_893_230,
        )
      end
    end

    context "when document_type does not indicate delete" do
      let(:message_hash) { json_fixture_as_hash("message_queue/republish_message.json") }

      it "calls put on the repository" do
        event.synchronize_to(repository)

        expect(repository).to have_received(:put).with(
          "f75d26a3-25a4-4c31-beea-a77cada4ce12",
          an_instance_of(PublishingEventPipeline::Document),
          payload_version: 65_861_808,
        )
      end
    end
  end
end
