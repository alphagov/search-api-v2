RSpec.describe DiscoveryEngine::Delete do
  subject(:delete) { described_class.new(client:) }

  let(:client) { double("DocumentService::Client", delete_document: nil) }
  let(:logger) { double("Logger", info: nil, warn: nil, error: nil) }

  before do
    allow(Rails).to receive(:logger).and_return(logger)
    allow(Rails.configuration).to receive(:discovery_engine_datastore).and_return("datastore-path")
    allow(GovukError).to receive(:notify)
  end

  context "when the delete succeeds" do
    before do
      allow(client).to receive(:delete_document)

      delete.call("some_content_id", payload_version: "1")
    end

    it "deletes the document" do
      expect(client).to have_received(:delete_document)
        .with(name: "datastore-path/branches/default_branch/documents/some_content_id")
    end

    it "logs the delete operation" do
      expect(logger).to have_received(:info).with("[GCDE][DELETE some_content_id@v1]")
    end
  end

  context "when the delete fails because the document doesn't exist" do
    let(:err) { Google::Cloud::NotFoundError.new("It got lost") }

    before do
      allow(client).to receive(:delete_document).and_raise(err)

      delete.call("some_content_id", payload_version: "1")
    end

    it "logs the failure" do
      expect(logger).to have_received(:warn).with("[GCDE][DELETE some_content_id@v1] It got lost")
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
      expect(logger).to have_received(:error).with("[GCDE][DELETE some_content_id@v1] Something went wrong")
    end

    it "send the error to Sentry" do
      expect(GovukError).to have_received(:notify).with(err)
    end
  end
end
