# Evaluation tasks using the Discovery Engine API to evaluate clickstream data
#
# The general flow for evaluations is as follows:
# • Create a sample query set and import sample queries from BigQuery
# • Create an evaluation for the sample query set
# • Wait for the evaluation to complete
# • Retrieve the evaluation results (either on a sample query set level or per query level)
# • Process the results (e.g., add to Prometheus metrics, store in BigQuery for analysis)
#
# Run the Rake tasks as follows:
# • bin/rails evaluation:clickstream:setup_sample_set
# • bin/rails evaluation:clickstream:create_evaluation[clickstream_2025-05]
# • bin/rails evaluation:clickstream:results[whatever-evaluation-id-you-got-from-the-previous-step]
#
# Gotchas:
# • The Sample Query Set, Sample Query, and Evaluation services operate on a _location_ level,
# unlike most other things we use in this app which are on the engine or datastore level.
# • The BigQuery table does not contain data for April, so we need to use the current month instead
# until it's June. This is a temporary workaround until we have data for April.
# • Our current "main" engine (`govuk`) is a legacy engine that doesn't support evaluation, so we
# need to switch to the new `govuk_global` engine first.
# • Only a single evaluation can be actively running at a given time across a location. Given that
# they start running when created, trying to create a new one while a previous one hasn't finished
# running yet will result in an error.
# • Creating a new evaluation returns an operation, but unlike other services the operation only
# reflects the creation of the evaluation, not the completion of it (so we need to manually poll its
# state)

namespace :evaluation do
  namespace :clickstream do
    desc "Create a sample query set for last month's clickstream data and import from BigQuery"
    task setup_sample_set: :environment do
      manager = DiscoveryEngine::Evaluation::SampleQuerySetManager.new

      # TODO: There is no data in BQ for April, so use the current month instead until it's June
      # Should really be:
      #   date = Time.zone.today.prev_month
      date = Time.zone.today

      sample_query_set = manager.create_and_import(date: date)
      puts "Created sample query set: #{sample_query_set.name}"
    end

    # e.g. bin/rails evaluation:clickstream:create_evaluation[clickstream_2025-05]
    desc "Run an evaluation for a sample query set by ID"
    task :create_evaluation, [:sample_set_id] => [:environment] do |_, args|
      sample_set_id = args[:sample_set_id]
      raise "Please provide a sample query set ID to evaluate" if sample_set_id.blank?

      runner = DiscoveryEngine::Evaluation::EvaluationRunner.new
      evaluation = runner.create_evaluation(sample_set_id)

      puts "Successfully created evaluation #{evaluation.name}"
    end

    # e.g. bin/rails evaluation:clickstream:results[5b3fc2b1-9c57-4da9-b9b6-ab39cd4bbdcd]
    desc "Get the results of an evaluation by ID"
    task :results, [:evaluation_id] => [:environment] do |_, args|
      evaluation_id = args[:evaluation_id]
      raise "Please provide an evaluation ID to get results for" if evaluation_id.blank?

      runner = DiscoveryEngine::Evaluation::EvaluationRunner.new
      retriever = DiscoveryEngine::Evaluation::ResultsRetriever.new

      puts "Getting results for evaluation: #{evaluation_id}"

      runner.wait_for_completion(evaluation_id)
      quality_metrics = retriever.get_quality_metrics(evaluation_id)

      pp quality_metrics
    end

    ### USEFUL DEBUGGING TASKS

    # e.g. bin/rails evaluation:clickstream:debug_delete[clickstream_2025-05]
    desc "Delete a sample query set by ID"
    task :debug_delete, [:id] => [:environment] do |_, args|
      id = args[:id]
      raise "Please provide a sample query set ID to delete" if id.blank?

      manager = DiscoveryEngine::Evaluation::SampleQuerySetManager.new
      manager.delete(id)
      puts "Deleted sample query set: #{id}"
    end

    desc "List all sample query sets and some sample queries"
    task debug_list: :environment do
      manager = DiscoveryEngine::Evaluation::SampleQuerySetManager.new

      puts "Sample Query Sets:"
      manager.list_all.each do |sample_query_set|
        puts "# #{sample_query_set.name} (#{sample_query_set.display_name})"

        manager.list_sample_queries(sample_query_set.name).each do |sample_query|
          entry = sample_query.query_entry
          puts "  • #{entry.query} (#{entry.targets.map(&:uri).join(', ')})"
        end

        puts
      end
    end

    desc "List all evaluations and their state"
    task debug_list_evaluations: :environment do
      runner = DiscoveryEngine::Evaluation::EvaluationRunner.new

      puts "Evaluations:"
      runner.list_all.each do |evaluation|
        created = evaluation.create_time.to_time
        puts "# #{evaluation.name} (created #{created}): #{evaluation.state}"
      end
    end
  end
end
