class PublishedDocumentsQueueConsumer
  def process(message)
    Rails.logger.info(message.payload)
    message.ack
  end
end
