RSpec.describe DiscoveryEngine::Clients do
  describe ".completion_service" do
    it "returns a completion service instance" do
      completion_service = described_class.completion_service
      expect(completion_service).to be_an_instance_of(Google::Cloud::DiscoveryEngine::V1::CompletionService::Client)
    end

    it "memoizes the service" do
      completion_service1 = described_class.completion_service
      completion_service2 = described_class.completion_service
      expect(completion_service1).to be(completion_service2)
    end
  end

  describe ".document_service" do
    it "returns a document service instance" do
      document_service = described_class.document_service
      expect(document_service).to be_an_instance_of(Google::Cloud::DiscoveryEngine::V1::DocumentService::Client)
    end

    it "memoizes the service" do
      document_service1 = described_class.document_service
      document_service2 = described_class.document_service
      expect(document_service1).to be(document_service2)
    end
  end

  describe ".search_service" do
    it "returns a search service instance" do
      search_service = described_class.search_service
      expect(search_service).to be_an_instance_of(Google::Cloud::DiscoveryEngine::V1::SearchService::Client)
    end

    it "memoizes the service" do
      search_service1 = described_class.search_service
      search_service2 = described_class.search_service
      expect(search_service1).to be(search_service2)
    end
  end

  describe ".user_event_service" do
    it "returns a user event service instance" do
      user_event_service = described_class.user_event_service
      expect(user_event_service).to be_an_instance_of(Google::Cloud::DiscoveryEngine::V1::UserEventService::Client)
    end

    it "memoizes the service" do
      user_event_service1 = described_class.user_event_service
      user_event_service2 = described_class.user_event_service
      expect(user_event_service1).to be(user_event_service2)
    end
  end
end
