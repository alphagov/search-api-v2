RSpec.describe DiscoveryEngine::Clients do
  after do
    described_class.instance_variable_set(:@completion_service, nil)
    described_class.instance_variable_set(:@search_service, nil)
  end

  shared_examples "a client with timeout configured" do |service_name, timeout|
    let(:config) { double("config") }
    let(:client) { double("client") }

    before do
      allow(config).to receive(:timeout=)
      allow(Google::Cloud::DiscoveryEngine).to receive(service_name) do |**_kwargs, &block|
        block.call(config) if block
        client
      end
    end

    it "initialises the client with the v1 API version" do
      subject
      expect(Google::Cloud::DiscoveryEngine).to have_received(service_name).with(version: :v1)
    end

    it "configures the client with a timeout" do
      subject
      expect(config).to have_received(:timeout=).with(timeout)
    end
  end

  describe ".search_service with 3 second timeout" do
    subject { described_class.search_service }

    include_examples "a client with timeout configured", :search_service, 4
  end

  describe ".completion_service with one second timeout" do
    subject { described_class.completion_service }

    include_examples "a client with timeout configured", :completion_service, 1
  end
end
