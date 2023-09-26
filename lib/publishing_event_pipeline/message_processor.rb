module PublishingEventPipeline
  # Processes incoming content changes from the publishing message queue.
  class MessageProcessor
    attr_reader :document_event_mapper, :repository

    def initialize(
      repository:,
      document_event_mapper: DocumentEventMapper.new
    )
      @repository = repository
      @document_event_mapper = document_event_mapper
    end

    # Implements the callback interface required by `govuk_message_queue_consumer`
    def process(message)
      event = document_event_mapper.call(message.payload)
      event.synchronize_to(repository)

      message.ack
    end
  end
end
