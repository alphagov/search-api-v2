RSpec.describe DiscoveryEngine::Sync::Put do
  subject(:put) { described_class.new(client:) }

  let(:client) { double("DocumentService::Client", update_document: nil) }
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

  context "when updating the document succeeds" do
    before do
      allow(client).to receive(:update_document).and_return(
        double(name: "document-name"),
      )

      put.call(
        "some_content_id",
        { foo: "bar" },
        content: "some content",
        payload_version: "1",
      )
    end

    it "updates the document" do
      expect(client).to have_received(:update_document).with(
        document: {
          id: "some_content_id",
          name: "branch/documents/some_content_id",
          json_data: "{\"foo\":\"bar\",\"payload_version\":\"1\"}",
          content: {
            mime_type: "text/html",
            raw_bytes: an_object_satisfying { |io| io.read == "some content" },
          },
        },
        allow_missing: true,
      )
    end

    it "locks the document by content_id during the update call" do
      expect(redlock_client).to have_received(:lock!).with(
        "search_api_v2:sync_lock:some_content_id",
        anything,
      )
    end

    it "sets the new latest remote version" do
      expect(redis_client).to have_received(:set).with(
        "search_api_v2:latest_synced_version:some_content_id",
        "1",
      )
    end

    it "logs the put operation" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::INFO,
        "[DiscoveryEngine::Sync::Put] Successfully added/updated content_id:some_content_id payload_version:1",
      )
    end
  end

  context "when the incoming document is older than the remote version" do
    before do
      allow(redis_client).to receive(:get)
        .with("search_api_v2:latest_synced_version:some_content_id").and_return("42")

      put.call(
        "some_content_id",
        { foo: "bar" },
        content: "some content",
        payload_version: "1",
      )
    end

    it "does not update the document" do
      expect(client).not_to have_received(:update_document)
    end

    it "does not set the remote version" do
      expect(redis_client).not_to have_received(:set)
    end

    it "logs that the document hasn't been updated" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::INFO,
        "[DiscoveryEngine::Sync::Put] Ignored as newer version (42) already synced content_id:some_content_id payload_version:1",
      )
    end
  end

  context "when locking the document fails" do
    let(:error) { Redlock::LockError.new("resource") }

    before do
      allow(redlock_client).to receive(:lock!).and_raise(error)

      put.call(
        "some_content_id",
        { foo: "bar" },
        content: "some content",
        payload_version: "1",
      )
    end

    it "updates the document regardless" do
      expect(client).to have_received(:update_document)
    end

    it "logs the failure" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::ERROR,
        "[DiscoveryEngine::Sync::Put] Failed to acquire lock for document: some_content_id, payload_version: 1. Continuing without lock.",
      )
    end

    it "sends the error to Sentry" do
      expect(GovukError).to have_received(:notify).with(error)
    end
  end

  context "when updating the document fails" do
    let(:err) { Google::Cloud::Error.new("Something went wrong") }

    before do
      allow(client).to receive(:update_document).and_raise(err)

      put.call("some_content_id", {}, payload_version: "1")
    end

    it "logs the failure" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::ERROR,
        "[DiscoveryEngine::Sync::Put] Failed to add/update document due to an error (Something went wrong) content_id:some_content_id payload_version:1",
      )
    end

    it "sends the error to Sentry" do
      expect(GovukError).to have_received(:notify).with(err)
    end
  end
end
