RSpec.describe DiscoveryEngine::Put do
  subject(:put) { described_class.new(client:) }

  let(:client) { double("DocumentService::Client", update_document: nil) }
  let(:logger) { double("Logger", add: nil) }

  before do
    allow(Rails).to receive(:logger).and_return(logger)
    allow(Rails.configuration).to receive(:discovery_engine_datastore).and_return("datastore-path")
    allow(GovukError).to receive(:notify)
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
          name: "datastore-path/branches/default_branch/documents/some_content_id",
          json_data: "{\"foo\":\"bar\",\"payload_version\":\"1\"}",
          content: {
            mime_type: "text/html",
            raw_bytes: an_object_satisfying { |io| io.read == "some content" },
          },
        },
        allow_missing: true,
      )
    end

    it "logs the put operation" do
      expect(logger).to have_received(:add).with(
        Logger::Severity::INFO,
        "[DiscoveryEngine::Put] Successfully added/updated content_id:some_content_id payload_version:1",
      )
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
        "[DiscoveryEngine::Put] Failed to add/update document due to an error (Something went wrong) content_id:some_content_id payload_version:1",
      )
    end

    it "send the error to Sentry" do
      expect(GovukError).to have_received(:notify).with(err)
    end
  end
end
