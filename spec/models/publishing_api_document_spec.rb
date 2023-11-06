RSpec.describe PublishingApiDocument do
  subject(:document) do
    described_class.new(
      document_hash,
      put_service:,
      delete_service:,
    )
  end

  let(:put_service) { double(:put_service, call: nil) }
  let(:delete_service) { double(:delete_service, call: nil) }

  let(:document_hash) do
    {
      content_id: "content-id",
      document_type:,
      base_path:,
      details: { url: },
      locale:,
      payload_version: "42",
    }
  end
  let(:base_path) { "/base-path" }
  let(:url) { nil }
  let(:locale) { "en" }

  describe "#synchronize" do
    before do
      allow(Rails.logger).to receive(:info)

      document.synchronize
    end

    %w[gone redirect substitute vanish].each do |document_type|
      context "when the document type is #{document_type}" do
        let(:document_type) { document_type }

        it "calls the delete service" do
          expect(delete_service).to have_received(:call).with("content-id", payload_version: 42)
        end
      end
    end

    context "when the document type is on the ignore list as a string" do
      let(:document_type) { "test_ignored_type" } # see test section in YAML config

      it "does not publish the document and logs a message" do
        expect(put_service).not_to have_received(:call)
        expect(Rails.logger).to have_received(:info).with("Ignoring document 'content-id'")
      end
    end

    context "when the document type is on the ignore list as a pattern" do
      let(:document_type) { "another_test_ignored_type_foo" } # see test section in YAML config

      it "does not publish the document and logs a message" do
        expect(put_service).not_to have_received(:call)
        expect(Rails.logger).to have_received(:info).with("Ignoring document 'content-id'")
      end
    end

    context "when the document doesn't have a base path or a details.url" do
      let(:document_type) { "internal" }
      let(:base_path) { nil }
      let(:url) { nil }

      it "does not publish the document and logs a message" do
        expect(put_service).not_to have_received(:call)
        expect(Rails.logger).to have_received(:info).with("Ignoring document 'content-id'")
      end
    end

    context "when the document doesn't have an English locale" do
      let(:document_type) { "dokument" }
      let(:locale) { "de" }

      it "does not publish the document and logs a message" do
        expect(put_service).not_to have_received(:call)
        expect(Rails.logger).to have_received(:info).with("Ignoring document 'content-id'")
      end
    end

    context "when the document type is on the ignore list but the path is excluded" do
      let(:document_type) { "test_ignored_type" } # see test section in YAML config
      let(:base_path) { "/test_ignored_path_override" } # see test section in YAML config

      it "calls the put service" do
        expect(put_service).to have_received(:call)
      end
    end

    context "when the document doesn't have a base path but does have a url" do
      let(:document_type) { "external_content" }
      let(:base_path) { nil }
      let(:url) { "https://www.example.com" }

      it "calls the put service" do
        expect(put_service).to have_received(:call)
      end
    end

    context "when the document has a blank locale but otherwise should be added" do
      let(:document_type) { "stuff" }
      let(:locale) { nil }

      it "calls the put service" do
        expect(put_service).to have_received(:call)
      end
    end

    context "when the document type is anything else" do
      let(:document_type) { "anything-else" }

      it "calls the put service" do
        expect(put_service).to have_received(:call)
      end
    end
  end
end
