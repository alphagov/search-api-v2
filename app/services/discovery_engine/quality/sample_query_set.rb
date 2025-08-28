module DiscoveryEngine
  module Quality
    class SampleQuerySet
      BIGQUERY_DATASET_ID = "automated_evaluation_input".freeze

      attr_reader :table_id

      def initialize(table_id:, month_label: nil, month: nil, year: nil)
        @month_label = month_label
        @month = month
        @year = year
        @table_id = table_id
      end

      def create_and_import_queries
        create_set
        import_queries
      end

      def name
        "#{Rails.application.config.discovery_engine_default_location_name}/sampleQuerySets/#{id}"
      end

      def display_name
        "#{table_id} #{partition_date}"
      end

    private

      attr_reader :month_label, :month, :year

      def create_set
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
      rescue Google::Cloud::AlreadyExistsError
        Rails.logger.warn("SampleQuerySet #{display_name} already exists. Skipping query set creation...")
      end

      def import_queries
        operation = DiscoveryEngine::Clients
          .sample_query_service
          .import_sample_queries(
            parent: name,
            bigquery_source: {
              dataset_id: BIGQUERY_DATASET_ID,
              table_id:,
              project_id: Rails.application.config.google_cloud_project_id,
              partition_date: {
                year: partition_date.year,
                month: partition_date.month,
                # Partition date needs to be a full date not just year-month
                day: 1,
              },
            },
          )
        operation.wait_until_done!

        raise operation.error.message if operation.error?

        Rails.logger.info("Successfully imported sample queries into: #{name}")
      end

      def description
        "Generated from #{partition_date} BigQuery #{table_id} data"
      end

      def partition_date
        case month_label

        when :last_month
          DiscoveryEngine::Quality::MonthInterval.previous_month
        when :month_before_last
          DiscoveryEngine::Quality::MonthInterval.previous_month(2)
        else
          DiscoveryEngine::Quality::MonthInterval.new(year, month)
        end
      end

      def id
        @id ||= "#{table_id}_#{partition_date}"
      end
    end
  end
end
