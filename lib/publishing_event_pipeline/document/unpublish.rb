module PublishingEventPipeline
  module Document
    class Unpublish < Base
      # When a document is unpublished in the source system, its document type changes to one of
      # these values. While semantically different for other systems, we only need to know that they
      # imply removal from search.
      UNPUBLISH_DOCUMENT_TYPES = %w[gone redirect substitute vanish].freeze

      # Returns whether this class can handle the given document hash.
      def self.handles?(document_hash)
        UNPUBLISH_DOCUMENT_TYPES.include?(document_hash.fetch("document_type"))
      end

      # Synchronize the document to the given repository (i.e. delete it from the repository).
      def synchronize_to(repository)
        repository.delete(content_id, payload_version:)
      end
    end
  end
end
