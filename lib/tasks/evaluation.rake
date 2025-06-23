namespace :evaluation do
  namespace :clickstream do
    desc "Create a sample query set for last month's clickstream data and import from BigQuery"
    task setup_sample_set: :environment do
      DiscoveryEngine::Evaluation::SampleQuerySet.new.create_and_import
    end

    desc "Create evaluation and fetch results"
    task :fetch_evaluations, [:sample_set_id] => [:environment] do |_, args|
      sample_set_id = args[:sample_set_id]

      raise "sample_set_id is required" unless sample_set_id

      er = DiscoveryEngine::Evaluation::EvaluationRunner.new(sample_set_id)
      er.fetch_quality_metrics
    end
  end
end
