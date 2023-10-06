require "govuk_message_queue_consumer"
require "jsonpath"
require "plek"

require "publishing_event_pipeline/configuration"
require "publishing_event_pipeline/message_processor"

require "publishing_event_pipeline/document"
require "publishing_event_pipeline/document/base"
require "publishing_event_pipeline/document/publish"
require "publishing_event_pipeline/document/unpublish"

module PublishingEventPipeline
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.run
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: PublishingEventPipeline.configuration.message_queue_name,
      processor: PublishingEventPipeline::MessageProcessor.new(
        repository: configuration.repository,
      ),
    ).run
  end
end
