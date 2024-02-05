class PublishingApiMessageProcessor
  # Implements the callback interface required by `govuk_message_queue_consumer`
  def process(message)
    Metrics::Exported.increment_counter(:incoming_messages)

    Metrics::Exported.observe_duration(:total_processing_duration) do
      document_hash = message.payload.deep_symbolize_keys
      document = PublishingApiDocument.new(document_hash)
      document.synchronize
    end

    message.ack
  rescue StandardError => e
    Metrics::Exported.increment_counter(:message_processing_errors)

    # TODO: Consider options for handling errors more granularly, and for differentiating between
    # retriable (e.g. transient connection issue) and fatal (e.g. malformed document on queue)
    # errors. For now while we aren't live, log an error, send the error to Sentry, and reject the
    # message to avoid unnecessary retries that would probably fail again while we're very actively
    # iterating.
    payload = if message.payload.is_a?(Hash)
                # Omit details as it may be large and is probably unnecessary
                message.payload.except("details")
              else
                message.payload
              end
    Rails.logger.error(<<~MSG)
      Failed to process incoming document message:
      #{e.class}: #{e.message}
      Message content: #{payload.inspect}
    MSG
    GovukError.notify(e)

    message.discard
  end
end
