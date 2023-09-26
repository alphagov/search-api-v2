module SearchRepositories
  module Null
    # A repository that does nothing, for use until we can integrate with the real product.
    class NullRepository
      def put(content_id, metadata, content: nil, payload_version: nil)
        content_snippet = content ? content[0..50] : "<no content>"

        Rails.logger.info(
          sprintf(
            "[%s] Persisted %s: %s (@v%s): '%s...'",
            self.class.name, content_id, metadata[:base_path], payload_version, content_snippet
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
