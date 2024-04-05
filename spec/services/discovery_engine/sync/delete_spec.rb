RSpec.describe DiscoveryEngine::Sync::Delete do
  subject(:delete) { described_class.new(client:) }

  let(:client) { double("DocumentService::Client", delete_document: nil) }
  let(:logger) { double("Logger", add: nil) }
  let(:redlock_client) { instance_double(Redlock::Client) }
  let(:redis_client) { instance_double(Redis, get: "0", set: nil) }

  before do
    allow(Rails).to receive(:logger).and_return(logger)
    allow(Rails.configuration).to receive(:discovery_engine_datastore_branch).and_return("branch")
    allow(GovukError).to receive(:notify)

    allow(Redlock::Client).to receive(:new).and_return(redlock_client)
    allow(redlock_client).to receive(:lock!)
      .with("search_api_v2:sync_lock:some_content_id", anything)
      .and_yield

    allow(Rails.application.config.redis_pool).to receive(:with).and_yield(redis_client)
  end

  context "when the delete succeeds" do
    before do
      delete.call("some_content_id", payload_version: "1")
    end

    it "deletes the document" do
      expect(client).to have_received(:delete_document)
        .with(name: "branch/documents/some_content_id")
    end

    it "sets the new latest remote version" do
      expect(redis_client).to have_received(:set).with(
        "search_api_v2:latest_synced_version:some_content_id",
        "1",
      )
    end

    it "logs the delete operation" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::INFO,
        "[DiscoveryEngine::Sync::Delete] Successfully deleted content_id:some_content_id payload_version:1",
      )
    end
  end

  context "when the incoming document is older than the remote version" do
    before do
      allow(redis_client).to receive(:get)
        .with("search_api_v2:latest_synced_version:some_content_id").and_return("42")

      delete.call("some_content_id", payload_version: "1")
    end

    it "does not delete the document" do
      expect(client).not_to have_received(:delete_document)
    end

    it "does not set the remote version" do
      expect(redis_client).not_to have_received(:set)
    end

    it "logs that the document hasn't been deleted" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::INFO,
        "[DiscoveryEngine::Sync::Delete] Ignored as newer version (42) already synced content_id:some_content_id payload_version:1",
      )
    end
  end

  context "when there is no remote version yet" do
    before do
      allow(redis_client).to receive(:get)
        .with("search_api_v2:latest_synced_version:some_content_id").and_return(nil)

      delete.call("some_content_id", payload_version: "1")
    end

    it "deletes the document" do
      expect(client).to have_received(:delete_document)
        .with(name: "branch/documents/some_content_id")
    end

    it "sets the new latest remote version" do
      expect(redis_client).to have_received(:set).with(
        "search_api_v2:latest_synced_version:some_content_id",
        "1",
      )
    end

    it "logs the delete operation" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::INFO,
        "[DiscoveryEngine::Sync::Delete] Successfully deleted content_id:some_content_id payload_version:1",
      )
    end
  end

  context "when locking the document fails" do
    let(:error) { Redlock::LockError.new("resource") }

    before do
      allow(redlock_client).to receive(:lock!).and_raise(error)

      delete.call("some_content_id", payload_version: "1")
    end

    it "deletes the document regardless" do
      expect(client).to have_received(:delete_document)
    end

    it "logs the failure" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::ERROR,
        "[DiscoveryEngine::Sync::Delete] Failed to acquire lock for document: some_content_id, payload_version: 1. Continuing without lock.",
      )
    end

    it "sends the error to Sentry" do
      expect(GovukError).to have_received(:notify).with(error)
    end
  end

  context "when the delete fails because the document doesn't exist" do
    let(:err) { Google::Cloud::NotFoundError.new("It got lost") }

    before do
      allow(client).to receive(:delete_document).and_raise(err)

      delete.call("some_content_id", payload_version: "1")
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

      delete.call("some_content_id", payload_version: "1")
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
