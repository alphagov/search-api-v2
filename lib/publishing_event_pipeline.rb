require "publishing_event_pipeline/configuration"
require "publishing_event_pipeline/document"
require "publishing_event_pipeline/document_lifecycle_event"

require "publishing_event_pipeline/message_processor"

require "publishing_event_pipeline/repositories/null_repository"

module PublishingEventPipeline
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
