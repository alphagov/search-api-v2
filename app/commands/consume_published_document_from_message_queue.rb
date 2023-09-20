class ConsumePublishedDocumentFromMessageQueue
  def self.process(message)
    new(message).call
  end

  attr_reader :message

  def initialize(message)
    @message = message
  end

  def call
    publish_event = PublishEvent.from_message_hash(message.payload)
    document = publish_event.document
    Rails.logger.info(
      sprintf(
        "Received %s: %s ('%s')",
        publish_event.update_type, document.content_id, document.title
      ),
    )
    message.ack
  rescue StandardError => e
    Rails.logger.error(
      sprintf(
        "Failed to handle message\nError: %s\nMessage: %s",
        e.message,
        message.inspect,
      ),
    )
  end
end
