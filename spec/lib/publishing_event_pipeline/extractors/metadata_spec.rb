RSpec.describe PublishingEventPipeline::Extractors::Metadata do
  subject(:extractor) { described_class.new }

  describe "#call" do
    let(:message_hash) { { "base_path" => "/test" } }

    it "extracts the base path" do
      expect(extractor.call(message_hash)).to eq({ base_path: "/test" })
    end

    context "when required items are missing" do
      let(:message_hash) { {} }

      it "raises an error" do
        expect { extractor.call(message_hash) }.to raise_error(KeyError)
      end
    end
  end
end
