require "govuk_message_queue_consumer"

require "publishing_event_pipeline/configuration"
require "publishing_event_pipeline/document_event_mapper"
require "publishing_event_pipeline/message_processor"

require "publishing_event_pipeline/events/publish"
require "publishing_event_pipeline/events/unpublish"
require "publishing_event_pipeline/extractors/content"
require "publishing_event_pipeline/extractors/metadata"

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
