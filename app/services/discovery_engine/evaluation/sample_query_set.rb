module DiscoveryEngine
  module Evaluation
    class SampleQuerySet
      def initialize(month, year)
        @month = month
        @year = year
      end

      def self.create(month:, year:)
        new(month, year)
      end

      def create_empty_set
        DiscoveryEngine::Clients
          .sample_query_set_service
          .create_sample_query_set(
            sample_query_set: {
              display_name: "Clickstream #{year}-#{month}",
              description: "Generated from #{year}-#{month} BigQuery clickstream data",
            },
            sample_query_set_id: "clickstream_#{year}-#{month}",
            parent: Rails.application.config.discovery_engine_default_location_name,
          )
      end

    private

      attr_reader :year, :month
    end
  end
end
