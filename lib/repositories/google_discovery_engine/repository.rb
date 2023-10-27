require "google/cloud/discovery_engine"

module Repositories
  module GoogleDiscoveryEngine
    # A repository integrating with Google Discovery Engine
    class Repository
      def initialize(
        client: ::Google::Cloud::DiscoveryEngine.document_service(version: :v1),
        logger: Logger.new($stdout, progname: self.class.name)
      )
        @client = client
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

      attr_reader :client, :logger
    end
  end
end
