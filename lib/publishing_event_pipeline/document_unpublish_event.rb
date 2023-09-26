module PublishingEventPipeline
  class DocumentUnpublishEvent
    attr_reader :content_id, :payload_version

    def initialize(content_id, payload_version:)
      @content_id = content_id
      @payload_version = payload_version
    end

    def synchronize_to(repository)
      repository.delete(content_id, payload_version:)
    end
  end
end
