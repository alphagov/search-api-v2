RSpec.describe PublishingEventPipeline::DocumentEventMapper do
  subject(:mapper) { described_class.new(content_extractor:, metadata_extractor:) }

  let(:content_extractor) { ->(message_hash) { message_hash.fetch("content") } }
  let(:metadata_extractor) { ->(message_hash) { message_hash.fetch("metadata") } }

  let(:message_hash) do
    {
      "content_id" => "content-id",
      "document_type" => document_type,
      "payload_version" => "payload-version",
      "content" => "the_content",
      "metadata" => "the_metadata",
    }
  end

  describe "#call" do
    context "when the document is any publishing type" do
      let(:document_type) { "spline-reticulation-report" }

      it "returns a publish event" do
        event = mapper.call(message_hash)

        expect(event).to be_a(PublishingEventPipeline::Events::Publish)
        expect(event.content_id).to eq("content-id")
        expect(event.content).to eq("the_content")
        expect(event.metadata).to eq("the_metadata")
        expect(event.payload_version).to eq("payload-version")
      end
    end

    %w[gone redirect substitute vanish].each do |unpublishing_type|
      context "when the document is an unpublishing type of #{unpublishing_type}" do
        let(:document_type) { unpublishing_type }

        it "returns an unpublish event" do
          event = mapper.call(message_hash)

          expect(event).to be_a(PublishingEventPipeline::Events::Unpublish)
          expect(event.content_id).to eq("content-id")
          expect(event.payload_version).to eq("payload-version")
        end
      end
    end
  end
end
