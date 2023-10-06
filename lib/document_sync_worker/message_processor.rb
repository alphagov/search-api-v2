module DocumentSyncWorker
  # Processes incoming content changes from the publishing message queue.
  class MessageProcessor
    attr_reader :repository

    def initialize(repository:)
      @repository = repository
    end

    # Implements the callback interface required by `govuk_message_queue_consumer`
    def process(message)
      document = Document.for(message.payload)
      document.synchronize_to(repository)

      message.ack
    rescue StandardError => e
      # TODO: Consider options for handling errors more granularly, and for differentiating between
      # retriable (e.g. transient connection issue in repository) and fatal (e.g. malformed document
      # on queue) errors. For now while we aren't live, log an error, send the error to Sentry, and
      # reject the message to avoid unnecessary retries that would probably fail again while we're
      # very actively iterating.
      payload = if message.payload.is_a?(Hash)
                  # Omit details as it may be large and is probably unnecessary
                  message.payload.except("details")
                else
                  message.payload
                end
      DocumentSyncWorker.logger.error(<<~MSG)
        Failed to process incoming document message:
        #{e.class}: #{e.message}
        Message content: #{payload.inspect}
      MSG
      GovukError.notify(e)

      message.discard
    end
  end
end
