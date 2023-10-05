RSpec.describe PublishingEventPipeline::Extractors::Metadata do
  subject(:extracted_data) { described_class.new.call(message_hash) }

  describe "#call" do
    describe "content_id" do
      subject(:content_id) { extracted_data[:content_id] }

      let(:message_hash) { { "content_id" => "000-000-000" } }

      it { is_expected.to eq("000-000-000") }
    end

    describe "document_type" do
      subject(:document_type) { extracted_data[:document_type] }

      let(:message_hash) { { "document_type" => "foo_bar" } }

      it { is_expected.to eq("foo_bar") }
    end

    describe "title" do
      subject(:title) { extracted_data[:title] }

      let(:message_hash) { { "title" => "Hello world" } }

      it { is_expected.to eq("Hello world") }
    end

    describe "description" do
      subject(:description) { extracted_data[:description] }

      let(:message_hash) { { "description" => "Lorem ipsum dolor sit amet." } }

      it { is_expected.to eq("Lorem ipsum dolor sit amet.") }
    end

    describe "link" do
      subject(:link) { extracted_data[:link] }

      context "with a base_path" do
        let(:message_hash) { { "base_path" => "/test" } }

        it { is_expected.to eq("/test") }
      end

      context "with an external URL" do
        let(:message_hash) { { "details" => { "url" => "https://liverpool.gov.uk/" } } }

        it { is_expected.to eq("https://liverpool.gov.uk/") }
      end

      context "with both a base_path and an external URL" do
        let(:message_hash) do
          { "base_path" => "/test", "details" => { "url" => "https://liverpool.gov.uk/" } }
        end

        it { is_expected.to eq("/test") }
      end

      context "without a base_path or external URL" do
        let(:message_hash) { {} }

        it { is_expected.to be_nil }
      end
    end

    describe "url" do
      subject(:url) { extracted_data[:url] }

      before do
        allow(Plek).to receive(:new).and_return(
          instance_double(Plek, website_root: "https://test.gov.uk"),
        )
      end

      context "with a base_path" do
        let(:message_hash) { { "base_path" => "/test" } }

        it { is_expected.to eq("https://test.gov.uk/test") }
      end

      context "with an external URL" do
        let(:message_hash) { { "details" => { "url" => "https://liverpool.gov.uk/" } } }

        it { is_expected.to eq("https://liverpool.gov.uk/") }
      end

      context "with both a base_path and an external URL" do
        let(:message_hash) do
          { "base_path" => "/test", "details" => { "url" => "https://liverpool.gov.uk/" } }
        end

        it { is_expected.to eq("https://test.gov.uk/test") }
      end

      context "without a base_path or external URL" do
        let(:message_hash) { {} }

        it { is_expected.to be_nil }
      end
    end

    describe "public_timestamp" do
      subject(:public_timestamp) { extracted_data[:public_timestamp] }

      let(:message_hash) { { "public_updated_at" => "2012-02-01T00:00:00Z" } }

      it { is_expected.to eq("2012-02-01T00:00:00Z") }
    end

    describe "public_timestamp_int" do
      subject(:public_timestamp_int) { extracted_data[:public_timestamp_int] }

      let(:message_hash) { { "public_updated_at" => "2012-02-01T00:00:00Z" } }

      it { is_expected.to eq(1_328_054_400) }

      context "without a public_timestamp" do
        let(:message_hash) { {} }

        it { is_expected.to be_nil }
      end
    end
  end
end
