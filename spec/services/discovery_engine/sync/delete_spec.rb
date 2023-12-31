RSpec.describe DiscoveryEngine::Sync::Delete do
  subject(:delete) { described_class.new(client:) }

  let(:client) { double("DocumentService::Client", delete_document: nil) }
  let(:logger) { double("Logger", add: nil) }

  before do
    allow(Rails).to receive(:logger).and_return(logger)
    allow(Rails.configuration).to receive(:discovery_engine_datastore_branch).and_return("branch")
    allow(GovukError).to receive(:notify)
  end

  context "when the delete succeeds" do
    before do
      allow(client).to receive(:delete_document)

      delete.call("some_content_id", payload_version: "1")
    end

    it "deletes the document" do
      expect(client).to have_received(:delete_document)
        .with(name: "branch/documents/some_content_id")
    end

    it "logs the delete operation" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::INFO,
        "[DiscoveryEngine::Sync::Delete] Successfully deleted content_id:some_content_id payload_version:1",
      )
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
