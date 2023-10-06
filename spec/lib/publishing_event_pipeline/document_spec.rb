RSpec.describe PublishingEventPipeline::Document do
  describe ".for" do
    subject(:document) { described_class.for(document_hash) }

    let(:document_hash) { double }

    context "when the document is handled by Unpublish" do
      before do
        allow(PublishingEventPipeline::Document::Unpublish)
          .to receive(:handles?).with(document_hash).and_return(true)
      end

      it "returns an Unpublish document" do
        expect(document).to be_a(PublishingEventPipeline::Document::Unpublish)
      end
    end

    context "when the document is not handled by Unpublish" do
      before do
        allow(PublishingEventPipeline::Document::Unpublish)
          .to receive(:handles?).with(document_hash).and_return(false)
      end

      it "returns a Publish document" do
        expect(document).to be_a(PublishingEventPipeline::Document::Publish)
      end
    end
  end
end
