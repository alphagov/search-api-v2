RSpec.describe PublishingEventPipeline::DocumentUnpublishEvent do
  subject(:event) { described_class.new(content_id, payload_version:) }

  let(:repository) { double(delete: nil) } # rubocop:disable RSpec/VerifiedDoubles (is an interface)
  let(:content_id) { "123" }
  let(:payload_version) { 1 }

  describe "#synchronize_to" do
    it "deletes the document from the repository" do
      event.synchronize_to(repository)

      expect(repository).to have_received(:delete).with(content_id, payload_version:)
    end
  end
end
