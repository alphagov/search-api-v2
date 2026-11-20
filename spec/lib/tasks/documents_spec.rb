RSpec.describe "documents tasks" do
  describe "documents:purge_all" do
    let(:task) { Rake::Task["documents:purge_all"] }
    let(:purge) { instance_double(DiscoveryEngine::Documents::Purge, call: nil) }

    before do
      allow(DiscoveryEngine::Documents::Purge).to receive(:new).and_return(purge)
      task.reenable
    end

    context "when not in production" do
      before do
        allow(GovukEnvironment).to receive(:current).and_return("integration")
      end

      it "purges all documents" do
        task.invoke

        expect(purge).to have_received(:call).once
      end
    end

    context "when in production" do
      before do
        allow(GovukEnvironment).to receive(:current).and_return("production")
      end

      it "does not purge documents" do
        expect {
          task.invoke
        }.to raise_error(SystemExit)

        expect(purge).not_to have_received(:call)
      end
    end
  end
end
