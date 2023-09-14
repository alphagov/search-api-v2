namespace :message_queue do
  desc "Create RabbitMQ queue for development environment"
  task create_queue: :environment do
    # The exchange, queue, and binding are created via Terraform outside of local development:
    # https://github.com/alphagov/govuk-aws/blob/main/terraform/projects/app-publishing-amazonmq/
    raise "This task should only be run in development" unless Rails.env.development?

    bunny = Bunny.new
    channel = bunny.start.create_channel
    exch = Bunny::Exchange.new(channel, :topic, "published_documents")
    channel.queue("search_api_v2_published_documents").bind(exch, routing_key: "*.*")
  end

  desc "Listens to and processes messages from the published documents queue"
  task consume_published_documents: :environment do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "search_api_v2_published_documents",
      processor: PublishedDocumentsQueueConsumer.new,
    ).run
  end
end
