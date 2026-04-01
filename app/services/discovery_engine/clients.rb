module DiscoveryEngine
  module Clients
  module_function

    def completion_service
      @completion_service ||= Google::Cloud::DiscoveryEngine.completion_service(version: :v1) do |config|
        config.timeout = 1.second
      end
    end

    def document_service
      @document_service ||= Google::Cloud::DiscoveryEngine.document_service(version: :v1)
    end

    def search_service
      @search_service ||= Google::Cloud::DiscoveryEngine.search_service(version: :v1) do |config|
        config.timeout = 4.seconds
      end
    end

    def user_event_service
      @user_event_service ||= Google::Cloud::DiscoveryEngine.user_event_service(version: :v1)
    end
  end
end
