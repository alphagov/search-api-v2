require "google/cloud/discovery_engine/v1beta"

module DiscoveryEngine
  module Clients
    extend self

    def sample_query_set_service
      @sample_query_set_service ||= v1beta_api::SampleQuerySetService::Client.new
    end

    def sample_query_service
      @sample_query_service ||= v1beta_api::SampleQueryService::Client.new
    end

    def evaluation_service
      @evaluation_service ||= v1beta_api::EvaluationService::Client.new
    end

  private

    def v1beta_api
      Google::Cloud::DiscoveryEngine::V1beta
    end
  end
end
