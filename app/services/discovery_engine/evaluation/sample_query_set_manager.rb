module DiscoveryEngine::Evaluation
  class SampleQuerySetManager
    def initialize(
      project_id: Rails.application.config.google_cloud_project_id,
      sample_query_set_client: ::Google::Cloud::DiscoveryEngine::V1beta::SampleQuerySetService::Client.new,
      sample_query_client: ::Google::Cloud::DiscoveryEngine::V1beta::SampleQueryService::Client.new
    )
      @project_id = project_id
      @sample_query_set_client = sample_query_set_client
      @sample_query_client = sample_query_client
    end

    def create_and_import(date: Time.zone.today.prev_month)
      id = "clickstream_#{date.strftime('%Y-%m')}"
      display_name = "Clickstream #{date.strftime('%b %Y')}"
      description = "Generated from #{date.strftime('%b %Y')} BigQuery clickstream data"

      Rails.logger.info("Creating sample query set: #{id}")

      sample_query_set = create_sample_query_set(id, display_name, description)
      import_from_bigquery(sample_query_set.name, date)

      sample_query_set
    end

    def delete(sample_query_set_id)
      name = "#{location}/sampleQuerySets/#{sample_query_set_id}"

      Rails.logger.info("Deleting sample query set: #{name}")

      sample_query_set_client.delete_sample_query_set(name: name)
    end

    def list_all
      sample_query_set_client.list_sample_query_sets(parent: location)
    end

    def list_sample_queries(sample_query_set_name, limit: 5)
      sample_query_client.list_sample_queries(parent: sample_query_set_name).first(limit)
    end

  private

    attr_reader :project_id, :sample_query_set_client, :sample_query_client

    def location
      @location ||= "projects/#{project_id}/locations/global"
    end

    def create_sample_query_set(id, display_name, description)
      sample_query_set_client.create_sample_query_set(
        sample_query_set: {
          display_name: display_name,
          description: description,
        },
        sample_query_set_id: id,
        parent: location,
      )
    end

    def import_from_bigquery(sample_query_set_name, date)
      bigquery_source = {
        dataset_id: "automated_evaluation_input",
        table_id: "clickstream",
        project_id: project_id,
        partition_date: {
          year: date.year,
          month: date.month,
          day: 1,
        },
      }

      Rails.logger.info("Importing sample queries from BigQuery source...")

      import_operation = sample_query_client.import_sample_queries(
        parent: sample_query_set_name,
        bigquery_source: bigquery_source,
      )

      import_operation.wait_until_done!

      if import_operation.error?
        error_message = "Error importing sample queries: #{import_operation.error.message}"
        Rails.logger.error(error_message)
        raise StandardError, error_message
      else
        Rails.logger.info("Successfully imported sample queries into: #{sample_query_set_name}")
      end
    end
  end
end
