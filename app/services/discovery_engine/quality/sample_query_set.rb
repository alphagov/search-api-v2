module DiscoveryEngine
  module Quality
    class SampleQuerySet
      include SampleQuerySetFields

      def initialize(year = nil, month = nil)
        @year = year&.to_i
        @month = month&.to_i
      end

      def create_and_import
        create
        import
      end

    private

      attr_reader :set, :year, :month

      def create
        @set = DiscoveryEngine::Clients
          .sample_query_set_service
          .create_sample_query_set(
            sample_query_set: {
              display_name: display_name(date),
              description: description(date),
            },
            sample_query_set_id: sample_query_set_id(date),
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

      def date
        return Time.zone.now.prev_month if year.nil? || month.nil?

        Date.new(year, month, 1)
      end
    end
  end
end
