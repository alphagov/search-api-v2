RSpec.describe "documents tasks" do
  describe "documents:purge_all" do
    let(:purge) { instance_double(DiscoveryEngine::Documents::Purge, call: nil) }

    before do
      allow(DiscoveryEngine::Documents::Purge).to receive(:new).and_return(purge)
      Rake::Task["documents:purge_all"].reenable
    end

    it "purges all documents when confirmed" do
      Rake::Task["documents:purge_all"].invoke

      expect(purge).to have_received(:call).once
    end
  end
end
