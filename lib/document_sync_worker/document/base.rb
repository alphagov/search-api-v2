module DocumentSyncWorker
  module Document
    # Abstract base class for documents that can be synchronized to a repository.
    class Base
      def initialize(document_hash)
        @document_hash = document_hash
      end

      # Synchronize the document to the given repository.
      def synchronize_to(repository)
        raise NotImplementedError, "You must use a concrete subclass of Document"
      end

      # The content ID of the document.
      def content_id
        document_hash.fetch("content_id")
      end

      # The payload version of the document.
      def payload_version
        document_hash.fetch("payload_version")
      end

    private

      attr_reader :document_hash
    end
  end
end
