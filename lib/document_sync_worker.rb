# Gems specific to the document sync worker are in their own group in the Gemfile
Bundler.require(:document_sync_worker)

require "document_sync_worker/configuration"
require "document_sync_worker/message_processor"

require "document_sync_worker/document"
require "document_sync_worker/document/base"
require "document_sync_worker/document/publish"
require "document_sync_worker/document/unpublish"

module DocumentSyncWorker
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.run
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: DocumentSyncWorker.configuration.message_queue_name,
      processor: DocumentSyncWorker::MessageProcessor.new(
        repository: configuration.repository,
      ),
    ).run
  end
end
