module DiscoveryEngine
  module Quality
    class SampleQuerySet
      BIGQUERY_DATASET_ID = "automated_evaluation_input".freeze
      BIGQUERY_TABLE_ID = "clickstream".freeze

      def initialize(month_interval)
        @month_interval = month_interval
      end

      def create_and_import
        create
        import
      end

      def id
        "#{BIGQUERY_TABLE_ID}_#{month_interval}"
      end

      def name
        "#{Rails.application.config.discovery_engine_default_location_name}/sampleQuerySets/#{id}"
      end

    private

      attr_reader :month_interval

      def create
        DiscoveryEngine::Clients
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
            parent: name,
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

        Rails.logger.info("Successfully imported sample queries into: #{name}")
      end

      def display_name
        "#{BIGQUERY_TABLE_ID} #{month_interval}"
      end

      def description
        "Generated from #{month_interval} BigQuery #{BIGQUERY_TABLE_ID} data"
      end
    end
  end
end
