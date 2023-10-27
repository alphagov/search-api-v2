require "document_sync_worker"
require "repositories/google_discovery_engine/repository"

namespace :document_sync_worker do
  desc "Create RabbitMQ queue for development environment"
  task create_queue: :environment do
    # The exchange, queue, and binding are created via Terraform outside of local development:
    # https://github.com/alphagov/govuk-aws/blob/main/terraform/projects/app-publishing-amazonmq/
    # TODO: Remove dependency on Rails if extracted to a separate unit
    raise "This task should only be run in development" unless Rails.env.development?

    bunny = Bunny.new
    channel = bunny.start.create_channel
    exch = Bunny::Exchange.new(channel, :topic, "published_documents")
    channel.queue(ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME")).bind(exch, routing_key: "*.*")
  end

  desc "Listens to and processes messages from the published documents queue"
  task run: :environment do
    DocumentSyncWorker.configure do |config|
      config.repository = Repositories::GoogleDiscoveryEngine::Repository.new(
        ENV.fetch("DISCOVERY_ENGINE_DATASTORE"),
        logger: config.logger,
      )
      config.message_queue_name = ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME")
    end

    DocumentSyncWorker.run
  end
end
