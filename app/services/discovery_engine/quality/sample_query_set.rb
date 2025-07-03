module DiscoveryEngine
  module Quality
    class SampleQuerySet
      include SampleQuerySetFields

      def initialize(month_interval)
        @month_interval = month_interval
      end

      def create_and_import
        create
        import
      end

    private

      attr_reader :set, :month_interval

      def create
        @set = DiscoveryEngine::Clients
          .sample_query_set_service
          .create_sample_query_set(
            sample_query_set: {
              display_name: display_name(month_interval),
              description: description(month_interval),
            },
            sample_query_set_id: sample_query_set_id(month_interval),
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
              table_id: BIGQUERY_TABLE_ID,
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
    end
  end
end
