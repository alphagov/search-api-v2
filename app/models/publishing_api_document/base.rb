module PublishingApiDocument
  # Abstract base class for documents from the Publishing API that can be synchronized to a service.
  # Concrete subclasses are responsible for implementing synchronization logic for their particular
  # type of document, which may involve creating or deleting a record remotely.
  class Base
    def initialize(document_hash)
      @document_hash = document_hash
    end

    # Synchronize the document to the given service.
    def synchronize(service: nil)
      raise NotImplementedError, "You must use a concrete subclass of Document"
    end

    # The content ID of the document.
    def content_id
      document_hash.fetch("content_id")
    end

    # The payload version of the document.
    def payload_version
      document_hash.fetch("payload_version").to_i
    end

  private

    attr_reader :document_hash
  end
end
