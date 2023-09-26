RSpec.describe PublishingEventPipeline::ContentExtractor do
  describe "#call" do
    subject(:content) { described_class.new.call(message_hash) }

    context "when body is present" do
      let(:message_hash) do
        {
          "details" => {
            "body" => "Lorem ipsum dolor sit amet.",
          },
        }
      end

      it { is_expected.to eq("Lorem ipsum dolor sit amet.") }
    end

    context "when body is not present" do
      let(:message_hash) do
        {
          "details" => {},
        }
      end

      it { is_expected.to be_nil }
    end
  end
end
