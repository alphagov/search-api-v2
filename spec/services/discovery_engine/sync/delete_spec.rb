require_relative "shared_examples"

RSpec.describe DiscoveryEngine::Sync::Delete do
  subject(:sync) { described_class.new("some_content_id", payload_version: "1", client:) }

  include_context "with sync context"

  let(:sync_required) { true }

  context "when the delete succeeds" do
    before do
      sync.call
    end

    it "deletes the document" do
      expect(client).to have_received(:delete_document)
        .with(name: "#{Branch.default.name}/documents/some_content_id")
    end

    it_behaves_like "a successful sync operation", "delete"
  end

  context "when the incoming document doesn't require syncing" do
    let(:sync_required) { false }

    before do
      sync.call
    end

    it "does not delete the document" do
      expect(client).not_to have_received(:delete_document)
    end

    it_behaves_like "a noop sync operation"
  end

  context "when locking the document fails" do
    before do
      allow(lock).to receive(:acquire).and_return(false)

      sync.call
    end

    it "deletes the document regardless" do
      expect(client).to have_received(:delete_document)
    end
  end

  context "when the delete fails because the document doesn't exist" do
    let(:err) { Google::Cloud::NotFoundError.new("It got lost") }

    before do
      allow(client).to receive(:delete_document).and_raise(err)

      sync.call
    end

    it "logs the failure" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::INFO,
        "[DiscoveryEngine::Sync::Delete] Did not delete document as it doesn't exist remotely (It got lost). content_id:some_content_id payload_version:1",
      )
    end

    it "does not send the error to Sentry" do
      expect(GovukError).not_to have_received(:notify)
    end
  end

  context "when failing consistently for the maximum number of attempts" do
    let(:err) { Google::Cloud::Error.new("Something went wrong") }

    before do
      allow(client).to receive(:delete_document).and_raise(err)

      sync.call
    end

    it_behaves_like "a failed sync operation after the maximum attempts", "delete"
  end

  context "when failing transiently but succeeding within the maximum attempts" do
    let(:err) { Google::Cloud::Error.new("Something went wrong") }

    before do
      allow(client).to receive(:delete_document).and_invoke(
        ->(_) { raise err },
        ->(_) { raise err },
        ->(_) { double(name: "document-name") },
      )

      sync.call
    end

    it "tries three times" do
      expect(client).to have_received(:delete_document).exactly(3).times
    end

    it_behaves_like "a sync operation that eventually succeeds", "delete"
  end
end
