module DiscoveryEngine
  module Quality
    class SampleQuerySet
      include SampleQuerySetFields

      def create_and_import
        create
        import
      end

    private

      attr_reader :set

      def create
        @set = DiscoveryEngine::Clients
          .sample_query_set_service
          .create_sample_query_set(
            sample_query_set: {
              display_name: display_name(last_month),
              description: description(last_month),
            },
            sample_query_set_id: sample_query_set_id(last_month),
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
                year: last_month.year,
                month: last_month.month,
                # Partition date needs to be a full date not just year-month
                day: 1,
              },
            },
          )
        operation.wait_until_done!

        raise operation.error.message if operation.error?

        Rails.logger.info("Successfully imported sample queries into: #{set.name}")
      end

      def last_month
        Time.zone.now.prev_month
      end
    end
  end
end
