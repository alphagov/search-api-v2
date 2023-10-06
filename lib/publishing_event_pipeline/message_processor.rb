module PublishingEventPipeline
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
    end
  end
end
