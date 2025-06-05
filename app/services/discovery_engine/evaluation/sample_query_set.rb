module DiscoveryEngine
  module Evaluation
    class SampleQuerySet
      def initialize(month, year)
        @month = month
        @year = year
        @set = create_empty_set
      end

      attr_reader :set

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

      def import_from_bigquery(dataset_id:, table_id:)
        operation = DiscoveryEngine::Clients
          .sample_query_service
          .import_sample_queries(
            parent: set.name,
            bigquery_source: {
              dataset_id:,
              table_id:,
              project_id: Rails.application.config.google_cloud_project_id,
              partition_date: {
                year: year,
                month: month,
                # Partition date needs to be a full date not just year-month
                day: 1,
              },
            },
          )
        operation.wait_until_done!

        raise operation.error.message if operation.error?

        Rails.logger.info("Successfully imported sample queries into: #{set.name}")
      end

    private

      attr_reader :year, :month
    end
  end
end
