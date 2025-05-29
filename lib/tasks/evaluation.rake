namespace :evaluation do
  namespace :clickstream do
    desc "Create a sample query set for last month's clickstream data and import from BigQuery"
    task setup_sample_set_for_last_month: :environment do
      sqs_client = Google::Cloud::DiscoveryEngine::V1beta::SampleQuerySetService::Client.new
      sq_client = Google::Cloud::DiscoveryEngine::V1beta::SampleQueryService::Client.new

      # Sample query set details
      location = "projects/#{Rails.application.config.google_cloud_project_id}/locations/global"
      # TODO: There is no data in BQ for April, so use the current month instead until it's June
      # prev_month = Time.zone.today.prev_month
      prev_month = Time.zone.today
      id = "clickstream_#{prev_month.strftime('%Y-%m')}"

      # Create a sample query set for last month's clickstream data
      sample_query_set = sqs_client.create_sample_query_set(
        sample_query_set: {
          display_name: "Clickstream #{prev_month.strftime('%b %Y')}",
          description: "Generated from #{prev_month.strftime('%b %Y')} BigQuery clickstream data",
        },
        sample_query_set_id: id,
        parent: location,
      )
      puts "Created sample query set: #{sample_query_set.name}"

      # Import the BigQuery source into the sample query set
      bigquery_source = {
        dataset_id: "automated_evaluation_input",
        table_id: "clickstream",
        project_id: Rails.application.config.google_cloud_project_id,
        partition_date: {
          year: prev_month.year,
          month: prev_month.month,
          # Partition date needs to be a full date not just year-month
          day: 1,
        },
      }
      import_operation = sq_client.import_sample_queries(
        parent: sample_query_set.name,
        bigquery_source:,
      )
      puts "Importing sample queries from BigQuery source..."
      import_operation.wait_until_done!

      # Ensure the import has gone okay
      if import_operation.error?
        puts "Error importing sample queries: #{import_operation.error.message}"
      else
        puts "Successfully imported sample queries into: #{sample_query_set.name}"
      end

      # Delete the sample query set again if needed
      # sqs_client.delete_sample_query_set(name: sample_query_set.name)
      # puts "Deleted sample query set: #{sample_query_set.name}"
    end

    # e.g. bin/rails evaluation:clickstream:evaluate[clickstream_2025-05]
    desc "Run an evaluation for a sample query set by ID"
    task :evaluate, [:id] => [:environment] do |_, args|
      id = args[:id]
      raise "Please provide a sample query set ID to evaluate" if id.blank?

      evaluation_client = Google::Cloud::DiscoveryEngine::V1beta::EvaluationService::Client.new

      location = "projects/#{Rails.application.config.google_cloud_project_id}/locations/global"
      sample_set_name = "projects/#{Rails.application.config.google_cloud_project_id}/locations/global/sampleQuerySets/#{id}"

      puts "Creating evaluation for sample query set: #{sample_set_name}..."
      operation = evaluation_client.create_evaluation(
        parent: location,
        evaluation: {
          evaluation_spec: {
            query_set_spec: {
              sample_query_set: sample_set_name,
            },
            search_request: {
              serving_config: ServingConfig.default.name,
            },
          },
        },
      )
      operation.wait_until_done!

      evaluation = operation.results
      raise "Error creating evaluation: #{operation.error.message}" if operation.error?

      puts "Successfully created evaluation #{evaluation.name}"

      while evaluation_client.get_evaluation(evaluation.name).state == :PENDING
        puts "Still waiting for evaluation to complete..."
        sleep 10
      end

      puts evaluation_client.get_evaluation(evaluation.name).inspect
    end

    ### USEFUL DEBUGGING TASKS

    # e.g. bin/rails evaluation:clickstream:debug_delete[clickstream_2025-05]
    desc "Delete a sample query set by ID"
    task :debug_delete, [:id] => [:environment] do |_, args|
      id = args[:id]
      raise "Please provide a sample query set ID to delete" if id.blank?

      sqs_client = Google::Cloud::DiscoveryEngine::V1beta::SampleQuerySetService::Client.new
      name = "projects/#{Rails.application.config.google_cloud_project_id}/locations/global/sampleQuerySets/#{id}"

      puts "Deleting sample query set: #{name}"
      sqs_client.delete_sample_query_set(name: name)
    end

    desc "List all sample query sets and some sample queries"
    task debug_list: :environment do
      sqs_client = Google::Cloud::DiscoveryEngine::V1beta::SampleQuerySetService::Client.new
      sq_client = Google::Cloud::DiscoveryEngine::V1beta::SampleQueryService::Client.new

      location = "projects/#{Rails.application.config.google_cloud_project_id}/locations/global"

      puts "Sample Query Sets:"
      sqs_client.list_sample_query_sets(parent: location).each do |sample_query_set|
        puts "# #{sample_query_set.name} (#{sample_query_set.display_name})"

        sq_client.list_sample_queries(parent: sample_query_set.name).first(5).each do |sample_query|
          entry = sample_query.query_entry
          puts "  • #{entry.query} (#{entry.targets.map(&:uri).join(', ')})"
        end

        puts
      end
    end
  end
end
