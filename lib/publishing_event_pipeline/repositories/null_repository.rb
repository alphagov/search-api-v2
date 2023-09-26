module PublishingEventPipeline
  module Repositories
    # A repository that does nothing, for use until we can integrate with the real product.
    class NullRepository
      def put(content_id, document, payload_version: nil)
        Rails.logger.info(
          sprintf(
            "[%s] Persisted %s: %s (@v%s)",
            self.class.name, content_id, document.metadata[:base_path], payload_version
          ),
        )
      end

      def delete(content_id, payload_version: nil)
        Rails.logger.info(
          sprintf(
            "[%s] Deleted %s (@v%s)",
            self.class.name, content_id, payload_version
          ),
        )
      end
    end
  end
end
