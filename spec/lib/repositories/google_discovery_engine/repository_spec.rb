require "repositories/google_discovery_engine/repository"

# Require v1 specifically to instance_double it (repository itself uses non-versioned API)
require "google/cloud/discovery_engine/v1"

RSpec.describe Repositories::GoogleDiscoveryEngine::Repository do
  let(:repository) { described_class.new(client:, logger:) }
  let(:client) { instance_double(Google::Cloud::DiscoveryEngine::V1::DocumentService::Client) }
  let(:logger) { instance_double(Logger, info: nil, warn: nil, error: nil) }

  before do
    allow(ENV).to receive(:fetch).with("DISCOVERY_ENGINE_DATASTORE").and_return("datastore-path")
    allow(GovukError).to receive(:notify)
  end

  describe "#put" do
    it "logs the put operation" do
      repository.put(
        "some_content_id",
        { link: "/some/path" },
        content: "Lorem ipsum dolor sit amet, consecutur edipiscing elit",
        payload_version: "1",
      )

      expect(logger).to have_received(:info).with(
        "[PUT some_content_id@v1] /some/path: " \
          "'Lorem ipsum dolor sit amet, consecutur edipiscing e...'",
      )
    end
  end

  describe "#delete" do
    context "when the delete succeeds" do
      before do
        allow(client).to receive(:delete_document)

        repository.delete("some_content_id", payload_version: "1")
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

        repository.delete("some_content_id", payload_version: "1")
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

        repository.delete("some_content_id", payload_version: "1")
      end

      it "logs the failure" do
        expect(logger).to have_received(:error).with("[GCDE][DELETE some_content_id@v1] Something went wrong")
      end

      it "send the error to Sentry" do
        expect(GovukError).to have_received(:notify).with(err)
      end
    end
  end
end
