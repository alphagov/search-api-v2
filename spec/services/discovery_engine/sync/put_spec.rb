require_relative "shared_examples"

RSpec.describe DiscoveryEngine::Sync::Put do
  subject(:sync) do
    described_class.new(
      "some_content_id",
      { foo: "bar" },
      content: "some content",
      payload_version: "1",
      client:,
    )
  end

  include_context "with sync context"

  let(:sync_required) { true }

  context "when updating the document succeeds" do
    before do
      allow(client).to receive(:update_document).and_return(double(name: "document-name"))

      sync.call
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

    it_behaves_like "a successful sync operation", "put"
  end

  context "when the incoming document doesn't need syncing" do
    let(:sync_required) { false }

    before do
      sync.call
    end

    it "does not update the document" do
      expect(client).not_to have_received(:update_document)
    end

    it_behaves_like "a noop sync operation"
  end

  context "when locking the document fails" do
    before do
      allow(lock).to receive(:acquire).and_return(false)

      sync.call
    end

    it "updates the document regardless" do
      expect(client).to have_received(:update_document)
    end
  end

  context "when failing consistently for the maximum number of attempts" do
    let(:err) { Google::Cloud::Error.new("Something went wrong") }

    before do
      allow(client).to receive(:update_document).and_raise(err)

      sync.call
    end

    it_behaves_like "a failed sync operation after the maximum attempts", "put"
  end

  context "when failing transiently but succeeding within the maximum attempts" do
    let(:err) { Google::Cloud::Error.new("Something went wrong") }

    before do
      allow(client).to receive(:update_document).and_invoke(
        ->(_) { raise err },
        ->(_) { raise err },
        ->(_) { double(name: "document-name") },
      )

      sync.call
    end

    it "tries three times" do
      expect(client).to have_received(:update_document).exactly(3).times
    end

    it_behaves_like "a sync operation that eventually succeeds", "put"
  end
end
