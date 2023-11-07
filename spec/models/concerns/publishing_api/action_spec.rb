RSpec.describe PublishingApi::Action do
  subject(:action) { concern_consumer.new(document_hash) }

  let(:concern_consumer) { Struct.new(:document_hash).include(described_class) }
  let(:document_hash) { { document_type:, base_path:, locale:, details: { url: } } }
  let(:base_path) { "/test_base_path" }
  let(:url) { nil }
  let(:locale) { "en" }

  %w[gone redirect substitute vanish].each do |document_type|
    context "when the document type is #{document_type}" do
      let(:document_type) { document_type }

      it { is_expected.to be_unpublish }
    end
  end

  context "when the document type is on the ignore list as a string" do
    let(:document_type) { "test_ignored_type" } # see test section in YAML config

    it { is_expected.to be_ignore }

    it "has the expected ignore_reason" do
      expect(action.ignore_reason).to eq("document_type on ignorelist (test_ignored_type)")
    end
  end

  context "when the document type is on the ignore list as a pattern" do
    let(:document_type) { "another_test_ignored_type_foo" } # see test section in YAML config

    it { is_expected.to be_ignore }

    it "has the expected ignore_reason" do
      expect(action.ignore_reason).to eq(
        "document_type on ignorelist (another_test_ignored_type_foo)",
      )
    end
  end

  context "when the document doesn't have a base path or a details.url" do
    let(:document_type) { "internal" }
    let(:base_path) { nil }
    let(:url) { nil }

    it { is_expected.to be_ignore }

    it "has the expected ignore_reason" do
      expect(action.ignore_reason).to eq("unaddressable")
    end
  end

  context "when the document doesn't have an English locale" do
    let(:document_type) { "dokument" }
    let(:locale) { "de" }

    it { is_expected.to be_ignore }

    it "has the expected ignore_reason" do
      expect(action.ignore_reason).to eq("locale not permitted (de)")
    end
  end

  context "when the document type is on the ignore list but the path is excluded" do
    let(:document_type) { "test_ignored_type" } # see test section in YAML config
    let(:base_path) { "/test_ignored_path_override" } # see test section in YAML config

    it { is_expected.to be_publish }
  end

  context "when the document doesn't have a base path but does have a url" do
    let(:document_type) { "external_content" }
    let(:base_path) { nil }
    let(:url) { "https://www.example.com" }

    it { is_expected.to be_publish }
  end

  context "when the document has a blank locale but otherwise should be added" do
    let(:document_type) { "stuff" }
    let(:locale) { nil }

    it { is_expected.to be_publish }
  end

  context "when the document type is anything else" do
    let(:document_type) { "anything-else" }

    it { is_expected.to be_publish }
  end
end
