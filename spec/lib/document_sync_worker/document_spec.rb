RSpec.describe DocumentSyncWorker::Document do
  describe ".for" do
    subject(:document) { described_class.for(document_hash) }

    let(:document_hash) { { "document_type" => document_type } }

    %w[gone redirect substitute vanish].each do |document_type|
      context "when the document type is #{document_type}" do
        let(:document_type) { document_type }

        it { is_expected.to be_a(DocumentSyncWorker::Document::Unpublish) }
      end
    end

    context "when the document type is not one of the unpublish document types" do
      let(:document_type) { "anything-else" }

      it { is_expected.to be_a(DocumentSyncWorker::Document::Publish) }
    end
  end
end
