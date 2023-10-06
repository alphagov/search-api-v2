require "document_sync_worker"
require "repositories/null/repository"

# TODO: For now, this lives within the application repository, but we may want to extract it to a
#   completely separate unit if we can keep dependencies between the read and write sides of this
#   project to a minimum. This isn't something that is 100% clear at this stage.
#
# Until then, these tasks intentionally run outside the Rails environment to avoid us adding any
# implicit dependencies on the Rails application.
#
# rubocop:disable Rails/RakeEnvironment
namespace :document_sync_worker do
  desc "Create RabbitMQ queue for development environment"
  task :create_queue do
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
  task :run do
    DocumentSyncWorker.configure do |config|
      # TODO: Once we have access to the search product and written a repository for it, this should
      #  be set to the real repository. Until then, this allows us to verify that the pipeline is
      #  working as expected through the logs.
      config.repository = Repositories::Null::Repository.new(logger: config.logger)
      config.message_queue_name = ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME")
    end

    DocumentSyncWorker.run
  end
end
# rubocop:enable Rails/RakeEnvironment
