RSpec.describe PublishingApiDocument::Ignore do
  subject(:document) { described_class.new(document_hash) }

  let(:content_id) { "123" }
  let(:payload_version) { "1" }
  let(:document_type) { "ignored" }
  let(:document_hash) do
    {
      "content_id" => content_id,
      "payload_version" => payload_version,
      "document_type" => document_type,
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
    let(:service) { double("A service", call: nil) }

    it "does not call the service" do
      document.synchronize(service:)

      expect(service).not_to have_received(:call)
    end
  end
end
