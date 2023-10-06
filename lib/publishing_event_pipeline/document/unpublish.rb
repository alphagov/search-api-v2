module PublishingEventPipeline
  module Document
    class Unpublish < Base
      # Synchronize the document to the given repository (i.e. delete it from the repository).
      def synchronize_to(repository)
        repository.delete(content_id, payload_version:)
      end
    end
  end
end
