module PublishingEventPipeline
  # Domain model for a content change event coming through from a publishing system
  class DocumentLifecycleEvent
    # When a document is unpublished in the source system, its document type changes to one of these
    # values. While semantically different for other sytems, we only need to know that they imply
    # removal from search.
    UNPUBLISH_DOCUMENT_TYPES = %w[gone redirect substitute vanish].freeze

    # Creates an instance from a message hash conforming to the publishing schema.
    def initialize(message_hash)
      # These fields *must* be present in the message hash, and we want to fail fast if they're not
      @content_id = message_hash.fetch("content_id")
      @document_type = message_hash.fetch("document_type")
      @payload_version = message_hash.fetch("payload_version")

      @document = Document.from_message_hash(message_hash) unless delete?
    end

    # Persists the document to, or removes it from, a repository for a search product.
    def synchronize_to(repository)
      if delete?
        repository.delete(content_id, payload_version:)
      else
        repository.put(content_id, document, payload_version:)
      end
    end

  private

    attr_reader :content_id, :document_type, :payload_version, :document

    def delete?
      UNPUBLISH_DOCUMENT_TYPES.include?(document_type)
    end
  end
end
