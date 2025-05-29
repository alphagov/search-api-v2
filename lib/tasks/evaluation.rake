require "google/cloud/discovery_engine/v1beta"

# Proof of concept for using the Discovery Engine API to evaluate clickstream data
#
# The general flow for evaluations is as follows:
# • Create a sample query set (`SampleQuerySetService::Client#create_sample_query_set`)
# • Import sample queries into the set from BigQuery
# (`SampleQuerySetService::Client#import_sample_queries`)
# • Create an evaluation for the sample query set (`EvaluationService::Client#create_evaluation`)
# • Wait for the evaluation to complete (`polling EvaluationService::Client#get_evaluation`)
# • Retrieve the evaluation results (either on a sample query set level using
# `EvaluationService::Client#get_evaluation`, or on a per query level using
# `EvaluationService::Client#list_evaluation_results`)
# • Do something with the results (probably adding the sample query set level results to Prometheus
# using the exporter, and chucking the per-query results into a BigQuery table for potential further
# analysis)
#
# Notes:
# • The Sample Query Set, Sample Query, and Evaluation services operate on a _location_ level,
# unlike most other things we use in this app which are on the engine or datastore level.
# • Gotcha: Our current "main" engine (`govuk`) is a legacy engine that doesn't support evaluation,
# so we need to switch to the new `govuk_global` engine first.
# • Gotcha: Only a single evaluation can run at a given time across a location
# • Gotcha: Creating a new evaluation returns an operation, but unlike other services the operation
# only reflects the creation of the evaluation, not the completion of it (so we need to manually
# poll its state)

namespace :evaluation do
  namespace :clickstream do
    # Global configuration for all tasks
    project_id = Rails.application.config.google_cloud_project_id
    location = "projects/#{project_id}/locations/global"

    # Clients
    sqs_client = Google::Cloud::DiscoveryEngine::V1beta::SampleQuerySetService::Client.new
    sq_client = Google::Cloud::DiscoveryEngine::V1beta::SampleQueryService::Client.new
    evaluation_client = Google::Cloud::DiscoveryEngine::V1beta::EvaluationService::Client.new

    desc "Create a sample query set for last month's clickstream data and import from BigQuery"
    task setup_sample_set_for_last_month: :environment do
      # Sample query set details
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
        project_id:,
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

      sample_set_name = "#{location}/sampleQuerySets/#{id}"

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

      name = "#{location}/sampleQuerySets/#{id}"

      puts "Deleting sample query set: #{name}"
      sqs_client.delete_sample_query_set(name: name)
    end

    desc "List all sample query sets and some sample queries"
    task debug_list: :environment do
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

    desc "List all evaluations and their state"
    task debug_list_evaluations: :environment do
      puts "Evaluations:"
      evaluation_client.list_evaluations(parent: location).each do |evaluation|
        created = evaluation.create_time.to_time
        puts "# #{evaluation.name} (created #{created}): #{evaluation.state}"
      end
    end
  end
end
