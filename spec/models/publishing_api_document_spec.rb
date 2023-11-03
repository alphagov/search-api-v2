RSpec.describe PublishingApiDocument do
  describe "#action" do
    subject(:document) { described_class.new(document_hash).action }

    let(:document_hash) do
      {
        document_type:,
        base_path:,
        details: { url: },
        locale:,
      }
    end
    let(:base_path) { "/base-path" }
    let(:url) { nil }
    let(:locale) { "en" }

    %w[gone redirect substitute vanish].each do |document_type|
      context "when the document type is #{document_type}" do
        let(:document_type) { document_type }

        it { is_expected.to be_a(PublishingApiAction::Unpublish) }
      end
    end

    context "when the document type is on the ignore list as a string" do
      let(:document_type) { "ignored" }

      before do
        allow(Rails.configuration).to receive(:document_type_ignorelist).and_return(%w[ignored])
      end

      it { is_expected.to be_a(PublishingApiAction::Ignore) }
    end

    context "when the document type is on the ignore list as a pattern" do
      let(:document_type) { "ignored_thing" }

      before do
        allow(Rails.configuration).to receive(:document_type_ignorelist).and_return([/^ignored_/])
      end

      it { is_expected.to be_a(PublishingApiAction::Ignore) }
    end

    context "when the document type is on the ignore list but the path is excluded" do
      let(:document_type) { "ignored" }

      before do
        allow(Rails.configuration).to receive(:document_type_ignorelist).and_return(%w[ignored])
        allow(Rails.configuration).to receive(:document_type_ignorelist_path_overrides)
          .and_return(%w[/base-path])
      end

      it { is_expected.to be_a(PublishingApiAction::Publish) }
    end

    context "when the document doesn't have an English locale" do
      let(:document_type) { "dokument" }
      let(:locale) { "de" }

      it { is_expected.to be_a(PublishingApiAction::Ignore) }
    end

    context "when the document doesn't have a base path or a details.url" do
      let(:document_type) { "internal" }
      let(:base_path) { nil }
      let(:url) { nil }

      it { is_expected.to be_a(PublishingApiAction::Ignore) }
    end

    context "when the document doesn't have a base path but does have a url" do
      let(:document_type) { "external_content" }
      let(:base_path) { nil }
      let(:url) { "https://www.example.com" }

      it { is_expected.to be_a(PublishingApiAction::Publish) }
    end

    context "when the document has a blank locale but otherwise should be added" do
      let(:document_type) { "stuff" }
      let(:locale) { nil }

      it { is_expected.to be_a(PublishingApiAction::Publish) }
    end

    context "when the document type is anything else" do
      let(:document_type) { "anything-else" }

      it { is_expected.to be_a(PublishingApiAction::Publish) }
    end
  end
end
