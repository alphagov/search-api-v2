require "govuk_message_queue_consumer"

require "publishing_event_pipeline/message_processor"

namespace :publishing_event_pipeline do
  desc "Create RabbitMQ queue for development environment"
  task create_queue: :environment do
    # The exchange, queue, and binding are created via Terraform outside of local development:
    # https://github.com/alphagov/govuk-aws/blob/main/terraform/projects/app-publishing-amazonmq/
    raise "This task should only be run in development" unless Rails.env.development?

    bunny = Bunny.new
    channel = bunny.start.create_channel
    exch = Bunny::Exchange.new(channel, :topic, "published_documents")
    channel.queue(ENV.fetch("PUBLISHING_EVENT_MESSAGE_QUEUE_NAME")).bind(exch, routing_key: "*.*")
  end

  desc "Listens to and processes messages from the published documents queue"
  task process_messages: :environment do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: ENV.fetch("PUBLISHING_EVENT_MESSAGE_QUEUE_NAME"),
      processor: PublishingEventPipeline::MessageProcessor,
    ).run
  end
end
