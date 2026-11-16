RSpec.describe DiscoveryEngine::Documents::Purge do
  subject(:purge) { described_class.new }

  let(:client) do
    instance_double(
      ::Google::Cloud::DiscoveryEngine::V1::DocumentService::Client,
      purge_documents: operation,
    )
  end
  let(:operation) { instance_double(Gapic::Operation, wait_until_done!: nil) }

  before do
    allow(DiscoveryEngine::Clients).to receive(:document_service).and_return(client)
  end

  describe "#call" do
    it "purges all documents from the default branch" do
      purge.call

      expect(client).to have_received(:purge_documents).with(
        parent: Branch.default.name,
        filter: "*",
        force: true,
      )
    end

    it "waits for the operation to finish" do
      purge.call

      expect(operation).to have_received(:wait_until_done!)
    end

    context "when the remote operation is successful" do
      let(:success_result) { double("success", error?: false, results: double(purge_count: 3)) }

      before do
        allow(operation).to receive(:wait_until_done!).and_yield(success_result)
        allow(Rails.logger).to receive(:info)
      end

      it "logs the number of purged documents" do
        purge.call

        expect(Rails.logger).to have_received(:info).with(/Successfully purged 3 documents/)
      end
    end

    context "when the remote operation is unsuccessful" do
      let(:error_result) { double("error", error?: true, results: double(message: "BROKEN")) }

      before do
        allow(operation).to receive(:wait_until_done!).and_yield(error_result)
      end

      it "raises an error" do
        expect { purge.call }.to raise_error("BROKEN")
      end
    end
  end
end
