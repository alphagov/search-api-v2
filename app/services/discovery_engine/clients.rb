module DiscoveryEngine
  module Clients
  module_function

    def completion_service
      @completion_service ||= Google::Cloud::DiscoveryEngine.completion_service(version: :v1) do |config|
        config.timeout = 1
      end
    end

    def document_service
      @document_service ||= Google::Cloud::DiscoveryEngine.document_service(version: :v1)
    end

    def search_service
      @search_service ||= Google::Cloud::DiscoveryEngine.search_service(version: :v1) do |config|
        config.timeout = 2.0
        config.retry_policy = {
          initial_delay: 1.0, # Seconds to wait before the first retry
          max_delay: 2.0, # Maximum delay between retries
          multiplier: 1.5, # Factor to increase delay by for each attempt
          # https://grpc.io/docs/guides/status-codes/
          retry_codes: %w[UNAVAILABLE DEADLINE_EXCEEDED INTERNAL],
        }
      end
    end

    def user_event_service
      @user_event_service ||= Google::Cloud::DiscoveryEngine.user_event_service(version: :v1)
    end
  end
end
