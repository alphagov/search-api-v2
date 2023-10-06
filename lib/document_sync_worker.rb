# Gems specific to the document sync worker are in their own group in the Gemfile
Bundler.require(:document_sync_worker)

module DocumentSyncWorker
  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/document_sync_worker", namespace: DocumentSyncWorker)
  loader.setup

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.logger
    configuration.logger
  end

  def self.run
    logger.info("Starting DocumentSyncWorker")
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: DocumentSyncWorker.configuration.message_queue_name,
      processor: DocumentSyncWorker::MessageProcessor.new(
        repository: configuration.repository,
      ),
    ).run
  rescue Interrupt
    logger.info("Stopping DocumentSyncWorker (received interrupt)")
  end
end
