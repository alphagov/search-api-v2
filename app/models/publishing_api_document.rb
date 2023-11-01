module PublishingApiDocument
  # When a document is unpublished in the source system, its document type changes to one of
  # these values. While semantically different for other systems, we only need to know that they
  # imply removal from search.
  UNPUBLISH_DOCUMENT_TYPES = %w[gone redirect substitute vanish].freeze

  # Factory method returning a Document instance of an appropriate concrete type for the given
  # document hash.
  def self.for(document_hash)
    case document_hash["document_type"]
    when *UNPUBLISH_DOCUMENT_TYPES
      Unpublish.new(document_hash)
    else
      Publish.new(document_hash)
    end
  end
end
