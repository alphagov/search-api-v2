module PublishingEventPipeline
  class DocumentEventMapper
    # When a document is unpublished in the source system, its document type changes to one of these
    # values. While semantically different for other systems, we only need to know that they imply
    # removal from search.
    UNPUBLISH_DOCUMENT_TYPES = %w[gone redirect substitute vanish].freeze

    def initialize(
      content_extractor: ContentExtractor.new,
      metadata_extractor: MetadataExtractor.new
    )
      @content_extractor = content_extractor
      @metadata_extractor = metadata_extractor
    end

    def call(message_hash)
      content_id = message_hash.fetch("content_id")
      document_type = message_hash.fetch("document_type")
      payload_version = message_hash.fetch("payload_version")

      if publishing_type?(document_type)
        metadata = metadata_extractor.call(message_hash)
        content = content_extractor.call(message_hash)

        DocumentPublishEvent.new(content_id, metadata, content:, payload_version:)
      else
        DocumentUnpublishEvent.new(content_id, payload_version:)
      end
    end

  private

    attr_reader :content_extractor, :metadata_extractor

    def publishing_type?(document_type)
      !UNPUBLISH_DOCUMENT_TYPES.include?(document_type)
    end
  end
end
