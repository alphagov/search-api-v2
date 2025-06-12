namespace :evaluation do
  namespace :clickstream do
    desc "Create a sample query set for last month's clickstream data and import from BigQuery"
    task setup_sample_set: :environment do
      DiscoveryEngine::Evaluation::SampleQuerySet.new.create_and_import
    end
  end
end
