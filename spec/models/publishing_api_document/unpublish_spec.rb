RSpec.describe PublishingApiDocument::Unpublish do
  subject(:document) { described_class.new(document_hash) }

  let(:content_id) { "123" }
  let(:payload_version) { "1" }
  let(:document_type) { "gone" }
  let(:document_hash) do
    {
      content_id:,
      payload_version:,
      document_type:,
    }
  end

  describe "#content_id" do
    it "returns the content_id from the document hash" do
      expect(document.content_id).to eq(content_id)
    end
  end

  describe "#payload_version" do
    it "returns the payload_version from the document hash" do
      expect(document.payload_version).to eq(1)
    end
  end

  describe "#synchronize" do
    let(:service) { double("Delete service", call: nil) }

    it "synchronises using a services" do
      document.synchronize(service:)

      expect(service).to have_received(:call).with(content_id, payload_version: 1)
    end
  end
end
