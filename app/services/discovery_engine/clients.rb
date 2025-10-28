module DiscoveryEngine
  module Clients
    extend self

    def completion_service
      @completion_service ||= Google::Cloud::DiscoveryEngine.completion_service(version: :v1)
    end

    def document_service
      @document_service ||= Google::Cloud::DiscoveryEngine.document_service(version: :v1)
    end

    def search_service
      @search_service ||= Google::Cloud::DiscoveryEngine.search_service(version: :v1)
    end

    def user_event_service
      @user_event_service ||= Google::Cloud::DiscoveryEngine.user_event_service(version: :v1)
    end
  end
end
