RSpec.describe PublishingEventPipeline::Extractors::Metadata do
  subject(:extracted_data) { described_class.new.call(message_hash) }

  describe "#call" do
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
  end
end
