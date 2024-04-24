namespace :document_sync_worker do
  desc "Create RabbitMQ queue for development environment"
  task create_queue: :environment do
    # This is a convenience task to create RabbitMQ resources for development purposes only.
    # The exchange, queue, and binding are created via Terraform outside of local development:
    # https://github.com/alphagov/govuk-aws/blob/main/terraform/projects/app-publishing-amazonmq/
    raise "This task should only be run in development" unless Rails.env.development?

    bunny = Bunny.new
    channel = bunny.start.create_channel
    exch = Bunny::Exchange.new(channel, :topic, "published_documents")
    channel.queue(ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME")).bind(exch, routing_key: "*.*")
  end

  desc "Listens to and processes messages from the published documents queue"
  task run: :environment do
    Rails.logger.info("Starting document sync worker")

    GovukMessageQueueConsumer::Consumer.new(
      queue_name: ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME"),
      processor: PublishingApiMessageProcessor.new,
      worker_threads: ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_THREADS", 1),
    ).run
  rescue Interrupt
    Rails.logger.info("Stopping document sync worker (received interrupt)")
  end
end
