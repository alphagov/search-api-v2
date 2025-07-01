module DiscoveryEngine
  module Quality
    class SampleQuerySet
      BIGQUERY_DATASET_ID = "automated_evaluation_input".freeze
      BIGQUERY_TABLE_ID = "clickstream".freeze

      def create_and_import
        create_sample_query_set
        import_from_bigquery
      end

    private

      attr_reader :set

      def create_sample_query_set
        @set = DiscoveryEngine::Clients
          .sample_query_set_service
          .create_sample_query_set(
            sample_query_set: {
              display_name: sample_query_set_display_name,
              description: sample_query_set_description,
            },
            sample_query_set_id:,
            parent: Rails.application.config.discovery_engine_default_location_name,
          )
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
                year: date.year,
                month: date.month,
                # Partition date needs to be a full date not just year-month
                day: 1,
              },
            },
          )
        operation.wait_until_done!

        raise operation.error.message if operation.error?

        Rails.logger.info("Successfully imported sample queries into: #{set.name}")
      end

      def sample_query_set_display_name
        "#{BIGQUERY_TABLE_ID} #{formatted_date}"
      end

      def sample_query_set_description
        "Generated from #{formatted_date} BigQuery #{BIGQUERY_TABLE_ID} data"
      end

      def sample_query_set_id
        "#{BIGQUERY_TABLE_ID}_#{formatted_date}"
      end

      def formatted_date
        date.strftime("%Y-%m")
      end

      def date
        Time.zone.now.prev_month
      end
    end
  end
end
