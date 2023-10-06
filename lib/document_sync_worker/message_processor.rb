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
    rescue StandardError
      # TODO: Consider options for handling errors more granularly, and for differentiating between
      # retriable (e.g. transient connection issue in repository) and fatal (e.g. malformed document
      # on queue) errors. For now while we aren't live, send the message to Sentry and reject it to
      # avoid unnecessary retries that would probably fail again while we're very actively
      # iterating.
      extra_info = if message.payload.is_a?(Hash)
                     # Omit details as it may be large and take us over the Sentry metadata limit
                     message.payload.except("details")
                   else
                     { message_payload: message.payload.to_s }
                   end
      GovukError.notify("Failed to process incoming document message", extra: extra_info)

      message.discard
    end
  end
end
