module DiscoveryEngine
  module Quality
    class SampleQuerySet
      BIGQUERY_DATASET_ID = "automated_evaluation_input".freeze

      def initialize(month_interval, table_id)
        @month_interval = month_interval
        @table_id = table_id
      end

      def create_and_import
        create
        import
      end

      def id
        @id ||= "#{table_id}_#{month_interval}"
      end

    private

      attr_reader :set, :month_interval, :table_id

      def create
        @set = DiscoveryEngine::Clients
          .sample_query_set_service
          .create_sample_query_set(
            sample_query_set: {
              display_name:,
              description:,
            },
            sample_query_set_id: id,
            parent: Rails.application.config.discovery_engine_default_location_name,
          )
      end

      def import
        operation = DiscoveryEngine::Clients
          .sample_query_service
          .import_sample_queries(
            parent: set.name,
            bigquery_source: {
              dataset_id: BIGQUERY_DATASET_ID,
              table_id:,
              project_id: Rails.application.config.google_cloud_project_id,
              partition_date: {
                year: month_interval.year,
                month: month_interval.month,
                # Partition date needs to be a full date not just year-month
                day: 1,
              },
            },
          )
        operation.wait_until_done!

        raise operation.error.message if operation.error?

        Rails.logger.info("Successfully imported sample queries into: #{set.name}")
      end

      def display_name
        "#{table_id} #{month_interval}"
      end

      def description
        "Generated from #{month_interval} BigQuery #{table_id} data"
      end
    end
  end
end
