module DiscoveryEngine
  module Evaluation
    class SampleQuerySet
      BIGQUERY_DATASET_ID = "automated_evaluation_input".freeze
      BIGQUERY_TABLE_ID = "clickstream".freeze

      def initialize(month, year, set)
        @month = month
        @year = year
        @set = set
      end

      attr_reader :set

      def self.create
        month = Time.zone.now.prev_month.month
        year = Time.zone.now.year
        sample_query_set = DiscoveryEngine::Clients
          .sample_query_set_service
          .create_sample_query_set(
            sample_query_set: {
              display_name: "Clickstream #{year}-#{month}",
              description: "Generated from #{year}-#{month} BigQuery clickstream data",
            },
            sample_query_set_id: "clickstream_#{year}-#{month}",
            parent: Rails.application.config.discovery_engine_default_location_name,
          )
        new(month, year, sample_query_set)
      end

      def import_from_bigquery
        operation = DiscoveryEngine::Clients
          .sample_query_service
          .import_sample_queries(
            parent: set.name,
            bigquery_source: {
              dataset_id: BIGQUERY_DATASET_ID,
              table_id: BIGQUERY_TABLE_ID,
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
