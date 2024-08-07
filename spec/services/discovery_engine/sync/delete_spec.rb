RSpec.describe DiscoveryEngine::Sync::Delete do
  let(:client) { double("DocumentService::Client", delete_document: nil) }
  let(:logger) { double("Logger", add: nil) }

  let(:lock) { instance_double(Coordination::DocumentLock, acquire: true, release: true) }

  let(:version_cache) { instance_double(Coordination::DocumentVersionCache, sync_required?: sync_required, set_as_latest_synced_version: nil) }
  let(:sync_required) { true }

  before do
    allow(Rails).to receive(:logger).and_return(logger)
    allow(Rails.configuration).to receive(:discovery_engine_datastore_branch).and_return("branch")
    allow(GovukError).to receive(:notify)

    allow(Coordination::DocumentLock).to receive(:new).with("some_content_id").and_return(lock)
    allow(Coordination::DocumentVersionCache).to receive(:new)
      .with("some_content_id", payload_version: "1").and_return(version_cache)
  end

  context "when the delete succeeds" do
    before do
      described_class.new("some_content_id", payload_version: "1", client:).call
    end

    it "deletes the document" do
      expect(client).to have_received(:delete_document)
        .with(name: "branch/documents/some_content_id")
    end

    it "sets the new latest remote version" do
      expect(version_cache).to have_received(:set_as_latest_synced_version)
    end

    it "logs the delete operation" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::INFO,
        "[DiscoveryEngine::Sync::Delete] Successful delete content_id:some_content_id payload_version:1",
      )
    end

    it "acquires and releases the lock" do
      expect(lock).to have_received(:acquire)
      expect(lock).to have_received(:release)
    end
  end

  context "when the incoming document doesn't require syncing" do
    let(:sync_required) { false }

    before do
      described_class.new("some_content_id", payload_version: "1", client:).call
    end

    it "does not delete the document" do
      expect(client).not_to have_received(:delete_document)
    end

    it "does not set the remote version" do
      expect(version_cache).not_to have_received(:set_as_latest_synced_version)
    end

    it "logs that the document hasn't been deleted" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::INFO,
        "[DiscoveryEngine::Sync::Delete] Ignored as newer version already synced content_id:some_content_id payload_version:1",
      )
    end
  end

  context "when locking the document fails" do
    before do
      allow(lock).to receive(:acquire).and_return(false)

      described_class.new("some_content_id", payload_version: "1", client:).call
    end

    it "deletes the document regardless" do
      expect(client).to have_received(:delete_document)
    end
  end

  context "when the delete fails because the document doesn't exist" do
    let(:err) { Google::Cloud::NotFoundError.new("It got lost") }

    before do
      allow(client).to receive(:delete_document).and_raise(err)

      described_class.new("some_content_id", payload_version: "1", client:).call
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

  context "when the delete fails for another reason" do
    let(:err) { Google::Cloud::Error.new("Something went wrong") }

    before do
      allow(client).to receive(:delete_document).and_raise(err)

      described_class.new("some_content_id", payload_version: "1", client:).call
    end

    it "logs the failure" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::ERROR,
        "[DiscoveryEngine::Sync::Delete] Failed to delete document due to an error (Something went wrong) content_id:some_content_id payload_version:1",
      )
    end

    it "send the error to Sentry" do
      expect(GovukError).to have_received(:notify).with(err)
    end
  end
end
