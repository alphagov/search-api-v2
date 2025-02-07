RSpec.describe DiscoveryEngine::Autocomplete::UpdateDenylist do
  subject(:update_denylist) { described_class.new(client:) }

  let(:client) do
    instance_double(
      ::Google::Cloud::DiscoveryEngine::V1::CompletionService::Client,
      purge_suggestion_deny_list_entries: purge_operation,
      import_suggestion_deny_list_entries: import_operation,
    )
  end
  let(:purge_operation) { instance_double(Gapic::Operation, wait_until_done!: nil, error?: false, results: purge_results) }
  let(:purge_results) { double("results") }
  let(:import_operation) { instance_double(Gapic::Operation, wait_until_done!: nil, error?: false, results: import_results) }
  let(:import_results) { double("results", failed_entries_count: 0, imported_entries_count: 100) }

  before do
    allow(Rails.configuration).to receive_messages(
      google_cloud_project_id: "my-fancy-project",
    )
  end

  describe "#call" do
    it "purges existing suggestion deny list entries" do
      update_denylist.call

      expect(client).to have_received(:purge_suggestion_deny_list_entries)
        .with(parent: DataStore.default.name)
      expect(purge_operation).to have_received(:wait_until_done!)
    end

    it "imports new suggestion deny list entries from GCS" do
      update_denylist.call

      expect(client).to have_received(:import_suggestion_deny_list_entries).with(
        gcs_source: {
          data_schema: "suggestion_deny_list",
          input_uris: ["gs://my-fancy-project_vais_artifacts/denylist.jsonl"],
        },
        parent: DataStore.default.name,
      )
      expect(import_operation).to have_received(:wait_until_done!)
    end

    context "when an error occurs during purge" do
      let(:purge_results) { double("results", message: "Purge failed") }

      before do
        allow(purge_operation).to receive(:error?).and_return(true)
      end

      it "raises an error" do
        expect { update_denylist.call }.to raise_error("Purge failed")
      end
    end

    context "when an error occurs during import" do
      let(:import_results) { double("results", message: "Import failed") }

      before do
        allow(import_operation).to receive(:error?).and_return(true)
      end

      it "raises an error" do
        expect { update_denylist.call }.to raise_error("Import failed")
      end
    end

    context "when there are failed entries during import" do
      let(:import_results) { double("results", failed_entries_count: 2, imported_entries_count: 0) }

      it "raises an error" do
        expect { update_denylist.call }.to raise_error("Failed to import 2 entries to autocomplete denylist")
      end
    end
  end
end
