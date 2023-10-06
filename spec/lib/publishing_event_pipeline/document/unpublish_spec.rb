RSpec.describe PublishingEventPipeline::Document::Unpublish do
  subject(:document) { described_class.new(document_hash) }

  let(:repository) do
    double("repository", delete: nil) # rubocop:disable RSpec/VerifiedDoubles (interface)
  end

  let(:content_id) { "123" }
  let(:payload_version) { 1 }
  let(:document_type) { "gone" }
  let(:document_hash) do
    {
      "content_id" => content_id,
      "payload_version" => payload_version,
      "document_type" => document_type,
    }
  end

  describe ".handles?" do
    subject(:handles) { described_class.handles?(document_hash) }

    %w[gone redirect substitute vanish].each do |document_type|
      context "when the document type is #{document_type}" do
        let(:document_type) { document_type }

        it { is_expected.to be(true) }
      end
    end

    context "when the document type is not one of the unpublish document types" do
      let(:document_type) { "anything-else" }

      it { is_expected.to be(false) }
    end
  end

  describe "#content_id" do
    it "returns the content_id from the document hash" do
      expect(document.content_id).to eq(content_id)
    end
  end

  describe "#payload_version" do
    it "returns the payload_version from the document hash" do
      expect(document.payload_version).to eq(payload_version)
    end
  end

  describe "#synchronize_to" do
    it "deletes the document from the repository" do
      document.synchronize_to(repository)

      expect(repository).to have_received(:delete).with(content_id, payload_version:)
    end
  end
end
