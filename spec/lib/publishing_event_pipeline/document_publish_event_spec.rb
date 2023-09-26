RSpec.describe PublishingEventPipeline::DocumentPublishEvent do
  subject(:event) { described_class.new(content_id, metadata, content:, payload_version:) }

  let(:repository) { double(put: nil) } # rubocop:disable RSpec/VerifiedDoubles (is an interface)

  let(:content_id) { "123" }
  let(:payload_version) { 1 }
  let(:content) { "content" }
  let(:metadata) { { foo: "bar" } }

  describe "#synchronize_to" do
    it "puts the document in the repository" do
      event.synchronize_to(repository)

      expect(repository).to have_received(:put).with(
        content_id, metadata, content:, payload_version:
      )
    end
  end
end
