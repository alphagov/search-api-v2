namespace :evaluation do
  namespace :clickstream do
    task test: :environment do
      # Create a sample query set for last month's clickstream data
      sqs_client = Google::Cloud::DiscoveryEngine::V1beta::SampleQuerySetService::Client.new
      parent = "projects/#{Rails.application.config.google_cloud_project_id}/locations/global"
      id = "clickstream_#{Time.zone.today.prev_month.strftime('%Y-%m')}"
      prev_month = Time.zone.today.prev_month
      sqs = sqs_client.create_sample_query_set(
        sample_query_set: {
          display_name: "Clickstream #{prev_month.strftime('%b %Y')}",
          description: "Generated from #{prev_month.strftime('%b %Y')} BigQuery clickstream data",
        },
        sample_query_set_id: id,
        parent:,
      )
      puts "Created sample query set: #{sqs.name}"
      

      # Delete the sample query set again
      sqs_client.delete_sample_query_set(name: sqs.name)
      puts "Deleted sample query set: #{sqs.name}"
    end
  end
end
