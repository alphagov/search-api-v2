class PublishedDocumentsQueueConsumer
  def process(message)
    document = Document.from_message_hash(message.payload)
    Rails.logger.info("Received message: #{document.content_id} ('#{document.title}')")
    message.ack
  end
end
