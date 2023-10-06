module PublishingEventPipeline
  module Document
    # Factory method returning a Document instance of an appropriate concrete type for the given
    # document hash.
    def self.for(document_hash)
      if Unpublish.handles?(document_hash)
        Unpublish.new(document_hash)
      else
        Publish.new(document_hash)
      end
    end
  end
end
