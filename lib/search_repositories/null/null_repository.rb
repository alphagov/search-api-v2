module SearchRepositories
  module Null
    # A repository that does nothing other than logging out any received calls, for use until we can
    # integrate with the real product.
    class NullRepository
      def initialize(logger: Logger.new($stdout, progname: self.class.name))
        @logger = logger
      end

      def put(content_id, metadata, content: nil, payload_version: nil)
        content_snippet = content ? content[0..50] : "<no content>"

        logger.info(
          sprintf(
            "[PUT %s@v%s] %s: '%s...'",
            content_id, payload_version, metadata[:base_path], content_snippet
          ),
        )
      end

      def delete(content_id, payload_version: nil)
        logger.info(sprintf("[DELETE %s@v%s]", content_id, payload_version))
      end

    private

      attr_reader :logger
    end
  end
end
