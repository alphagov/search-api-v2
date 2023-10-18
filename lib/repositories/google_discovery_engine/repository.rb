module Repositories
  module GoogleDiscoveryEngine
    # A repository integrating with Google Discovery Engine
    # TODO: This is just a copy of the Null repository to start off with, but it should be updated
    #       to integrate with the real product.
    class Repository
      def initialize(logger: Logger.new($stdout, progname: self.class.name))
        @logger = logger
      end

      def put(content_id, metadata, content: nil, payload_version: nil)
        content_snippet = content ? content[0..50] : "<no content>"

        logger.info(
          sprintf(
            "[PUT %s@v%s] %s: '%s...'",
            content_id, payload_version, metadata[:link], content_snippet
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
