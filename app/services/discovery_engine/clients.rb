require "google/cloud/discovery_engine/v1beta"

module DiscoveryEngine
  module Clients
    extend self

    def completion_service
      @completion_service ||= Google::Cloud::DiscoveryEngine.completion_service(version: :v1)
    end

    def document_service
      @document_service ||= Google::Cloud::DiscoveryEngine.document_service(version: :v1)
    end

    def evaluation_service
      @evaluation_service ||= v1beta_api::EvaluationService::Client.new
    end

    def sample_query_service
      @sample_query_service ||= v1beta_api::SampleQueryService::Client.new
    end

    def sample_query_set_service
      @sample_query_set_service ||= v1beta_api::SampleQuerySetService::Client.new
    end

    def search_service
      @search_service ||= Google::Cloud::DiscoveryEngine.search_service(version: :v1)
    end

    def user_event_service
      @user_event_service ||= Google::Cloud::DiscoveryEngine.user_event_service(version: :v1)
    end

  private

    def v1beta_api
      Google::Cloud::DiscoveryEngine::V1beta
    end
  end
end
