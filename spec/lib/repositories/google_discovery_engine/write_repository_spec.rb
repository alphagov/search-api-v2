require "repositories/google_discovery_engine/write_repository"

# Require v1 specifically to instance_double it (repository itself uses non-versioned API)
require "google/cloud/discovery_engine/v1"

RSpec.describe Repositories::GoogleDiscoveryEngine::WriteRepository do
  let(:repository) do
    described_class.new(
      "datastore-path",
      branch_name: "my_branch",
      client:,
      logger:,
    )
  end
  let(:client) { instance_double(Google::Cloud::DiscoveryEngine::V1::DocumentService::Client) }
  let(:logger) { instance_double(Logger, info: nil, warn: nil, error: nil) }

  before do
    allow(GovukError).to receive(:notify)
  end

  describe "#put" do
    context "when updating the document succeeds" do
      before do
        allow(client).to receive(:update_document).and_return(
          double(name: "document-name"), # rubocop:disable RSpec/VerifiedDoubles
        )

        repository.put(
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
            name: "datastore-path/branches/my_branch/documents/some_content_id",
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
        expect(logger).to have_received(:info).with("[GCDE][PUT some_content_id@v1] -> document-name")
      end
    end

    context "when updating the document fails" do
      let(:err) { Google::Cloud::Error.new("Something went wrong") }

      before do
        allow(client).to receive(:update_document).and_raise(err)

        repository.put("some_content_id", {}, payload_version: "1")
      end

      it "logs the failure" do
        expect(logger).to have_received(:error).with("[GCDE][PUT some_content_id@v1] Something went wrong")
      end

      it "send the error to Sentry" do
        expect(GovukError).to have_received(:notify).with(err)
      end
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
          .with(name: "datastore-path/branches/my_branch/documents/some_content_id")
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
