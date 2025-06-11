namespace :evaluation do
  namespace :clickstream do
    desc "Create a sample query set for last month's clickstream data and import from BigQuery"
    task :setup_sample_set, [:table_id] => :environment do |_, args|
      args.with_defaults(table_id: DiscoveryEngine::Evaluation::SampleQuerySet::BIGQUERY_TABLE_ID)

      sqs = DiscoveryEngine::Evaluation::SampleQuerySet.create(table_id: args[:table_id])
      sqs.import_from_bigquery
    end
  end
end
