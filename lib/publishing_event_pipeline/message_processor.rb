module PublishingEventPipeline
  # Processes incoming content changes from the publishing message queue.
  class MessageProcessor
    attr_reader :event_class, :repository

    def initialize(
      repository:,
      event_class: DocumentLifecycleEvent
    )
      @repository = repository
      @event_class = event_class
    end

    # Implements the callback interface required by `govuk_message_queue_consumer`
    def process(message)
      event = event_class.new(message.payload)
      event.synchronize_to(repository)

      message.ack
    end
  end
end
