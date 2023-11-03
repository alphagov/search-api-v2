RSpec.describe PublishingApiDocument do
  describe ".for" do
    subject(:document) { described_class.for(document_hash) }

    let(:document_hash) do
      {
        document_type:,
        base_path:,
        locale:,
      }
    end
    let(:base_path) { "/base-path" }
    let(:locale) { "en" }

    %w[gone redirect substitute vanish].each do |document_type|
      context "when the document type is #{document_type}" do
        let(:document_type) { document_type }

        it { is_expected.to be_a(PublishingApiDocument::Unpublish) }
      end
    end

    context "when the document type is on the ignore list as a string" do
      let(:document_type) { "ignored" }

      before do
        allow(Rails.configuration).to receive(:document_type_ignorelist).and_return(%w[ignored])
      end

      it { is_expected.to be_a(PublishingApiDocument::Ignore) }
    end

    context "when the document type is on the ignore list as a pattern" do
      let(:document_type) { "ignored_thing" }

      before do
        allow(Rails.configuration).to receive(:document_type_ignorelist).and_return([/^ignored_/])
      end

      it { is_expected.to be_a(PublishingApiDocument::Ignore) }
    end

    context "when the document type is on the ignore list but the path is excluded" do
      let(:document_type) { "ignored" }

      before do
        allow(Rails.configuration).to receive(:document_type_ignorelist).and_return(%w[ignored])
        allow(Rails.configuration).to receive(:document_type_ignorelist_path_overrides)
          .and_return(%w[/base-path])
      end

      it { is_expected.to be_a(PublishingApiDocument::Publish) }
    end

    context "when the document doesn't have an English locale" do
      let(:document_type) { "dokument" }
      let(:locale) { "de" }

      it { is_expected.to be_a(PublishingApiDocument::Ignore) }
    end

    context "when the document has a blank locale but otherwise should be added" do
      let(:document_type) { "stuff" }
      let(:locale) { nil }

      it { is_expected.to be_a(PublishingApiDocument::Publish) }
    end

    context "when the document type is anything else" do
      let(:document_type) { "anything-else" }

      it { is_expected.to be_a(PublishingApiDocument::Publish) }
    end
  end
end
