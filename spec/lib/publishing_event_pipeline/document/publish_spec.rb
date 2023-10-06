RSpec.describe PublishingEventPipeline::Document::Publish do
  subject(:document) { described_class.new(document_hash) }

  let(:repository) do
    double("repository", put: nil) # rubocop:disable RSpec/VerifiedDoubles (interface)
  end

  let(:content_id) { "123" }
  let(:payload_version) { 1 }
  let(:document_type) { "press_release" }
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
      expect(document.payload_version).to eq(payload_version)
    end
  end

  describe "#content" do
    subject(:extracted_content) { document.content }

    describe "with basic top-level fields" do
      let(:document_hash) do
        {
          "details" => {
            "body" => "a",
            "description" => "b",
            "hidden_search_terms" => "c",
            "introduction" => "d",
            "introductory_paragraph" => "e",
            "more_information" => "f",
            "need_to_know" => "g",
            "summary" => "h",
            "title" => "i",
          },
        }
      end

      it { is_expected.to eq("a\nb\nc\nd\ne\nf\ng\nh\ni") }
    end

    describe "with hidden indexable content" do
      let(:document_hash) do
        {
          "details" => {
            "metadata" => {
              "hidden_indexable_content" => %w[x y z],
            },
          },
        }
      end

      it { is_expected.to eq("x\ny\nz") }
    end

    describe "with a project code" do
      let(:document_hash) do
        {
          "details" => {
            "metadata" => {
              "project_code" => "PRINCE2",
            },
          },
        }
      end

      it { is_expected.to eq("PRINCE2") }
    end

    describe "with contact groups" do
      let(:document_hash) do
        {
          "details" => {
            "contact_groups" => [
              { "title" => "x" },
              { "title" => "y" },
              { "title" => "z" },
            ],
          },
        }
      end

      it { is_expected.to eq("x\ny\nz") }
    end

    describe "with parts" do
      let(:document_hash) do
        {
          "details" => {
            "parts" => [
              { "title" => "x", "body" => "a" },
              { "title" => "y", "body" => "b" },
              { "title" => "z", "body" => "c" },
            ],
          },
        }
      end

      it { is_expected.to eq("x\na\ny\nb\nz\nc") }
    end

    describe "without any fields" do
      let(:document_hash) do
        {
          "details" => {},
        }
      end

      it { is_expected.to be_blank }
    end
  end

  describe "#metadata" do
    describe "content_id" do
      subject(:extracted_content_id) { document.metadata[:content_id] }

      let(:document_hash) { { "content_id" => "000-000-000" } }

      it { is_expected.to eq("000-000-000") }
    end

    describe "document_type" do
      subject(:extracted_document_type) { document.metadata[:document_type] }

      let(:document_hash) { { "document_type" => "foo_bar" } }

      it { is_expected.to eq("foo_bar") }
    end

    describe "title" do
      subject(:extracted_title) { document.metadata[:title] }

      let(:document_hash) { { "title" => "Hello world" } }

      it { is_expected.to eq("Hello world") }
    end

    describe "description" do
      subject(:extracted_description) { document.metadata[:description] }

      let(:document_hash) { { "description" => "Lorem ipsum dolor sit amet." } }

      it { is_expected.to eq("Lorem ipsum dolor sit amet.") }
    end

    describe "link" do
      subject(:extracted_link) { document.metadata[:link] }

      context "with a base_path" do
        let(:document_hash) { { "base_path" => "/test" } }

        it { is_expected.to eq("/test") }
      end

      context "with an external URL" do
        let(:document_hash) { { "details" => { "url" => "https://liverpool.gov.uk/" } } }

        it { is_expected.to eq("https://liverpool.gov.uk/") }
      end

      context "with both a base_path and an external URL" do
        let(:document_hash) do
          { "base_path" => "/test", "details" => { "url" => "https://liverpool.gov.uk/" } }
        end

        it { is_expected.to eq("/test") }
      end

      context "without a base_path or external URL" do
        let(:document_hash) { {} }

        it { is_expected.to be_nil }
      end
    end

    describe "url" do
      subject(:extracted_url) { document.metadata[:url] }

      before do
        allow(Plek).to receive(:new).and_return(
          instance_double(Plek, website_root: "https://test.gov.uk"),
        )
      end

      context "with a base_path" do
        let(:document_hash) { { "base_path" => "/test" } }

        it { is_expected.to eq("https://test.gov.uk/test") }
      end

      context "with an external URL" do
        let(:document_hash) { { "details" => { "url" => "https://liverpool.gov.uk/" } } }

        it { is_expected.to eq("https://liverpool.gov.uk/") }
      end

      context "with both a base_path and an external URL" do
        let(:document_hash) do
          { "base_path" => "/test", "details" => { "url" => "https://liverpool.gov.uk/" } }
        end

        it { is_expected.to eq("https://test.gov.uk/test") }
      end

      context "without a base_path or external URL" do
        let(:document_hash) { {} }

        it { is_expected.to be_nil }
      end
    end

    describe "public_timestamp" do
      subject(:extracted_public_timestamp) { document.metadata[:public_timestamp] }

      let(:document_hash) { { "public_updated_at" => "2012-02-01T00:00:00Z" } }

      it { is_expected.to eq("2012-02-01T00:00:00Z") }
    end

    describe "public_timestamp_int" do
      subject(:extracted_public_timestamp_int) { document.metadata[:public_timestamp_int] }

      let(:document_hash) { { "public_updated_at" => "2012-02-01T00:00:00Z" } }

      it { is_expected.to eq(1_328_054_400) }

      context "without a public_timestamp" do
        let(:document_hash) { {} }

        it { is_expected.to be_nil }
      end
    end
  end

  describe "#synchronize_to" do
    it "puts the document in the repository" do
      document.synchronize_to(repository)

      expect(repository).to have_received(:put).with(
        content_id, document.metadata, content: document.content, payload_version:
      )
    end
  end
end
