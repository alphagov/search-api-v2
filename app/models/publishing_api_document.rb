module PublishingApiDocument
  # When a document is unpublished in the source system, its document type changes to one of
  # these values. While semantically different for other systems, we only need to know that they
  # imply removal from search.
  UNPUBLISH_DOCUMENT_TYPES = %w[gone redirect substitute vanish].freeze

  # Factory method returning a Document instance of an appropriate concrete type for the given
  # document hash.
  def self.for(document_hash)
    case document_hash[:document_type]
    when *UNPUBLISH_DOCUMENT_TYPES
      Unpublish.new(document_hash)
    when *Rails.configuration.document_type_ignorelist
      return Publish.new(document_hash) if force_add_path?(document_hash[:base_path])

      Ignore.new(document_hash)
    else
      return Ignore.new(document_hash) unless document_hash[:locale].in?(["en", nil])

      Publish.new(document_hash)
    end
  end

  # Returns whether the given base path should be added to the search index, even if its document
  # type is on the ignorelist.
  def self.force_add_path?(base_path)
    Rails.configuration.document_type_ignorelist_path_overrides.any? { _1.match?(base_path) }
  end
end
