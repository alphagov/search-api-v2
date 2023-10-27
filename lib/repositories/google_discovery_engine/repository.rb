require "google/cloud/discovery_engine"

module Repositories
  module GoogleDiscoveryEngine
    # A repository integrating with Google Discovery Engine
    class Repository
      DEFAULT_BRANCH_NAME = "default_branch".freeze

      def initialize(
        datastore_path,
        branch_name: DEFAULT_BRANCH_NAME,
        client: ::Google::Cloud::DiscoveryEngine.document_service(version: :v1),
        logger: Logger.new($stdout, progname: self.class.name)
      )
        @datastore_path = datastore_path
        @branch_name = branch_name
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
        client.delete_document(name: document_name(content_id))

        logger.info(sprintf("[GCDE][DELETE %s@v%s]", content_id, payload_version))
      rescue Google::Cloud::NotFoundError => e
        # TODO: Should we eventually send this to Sentry? A document not existing is a relatively
        # common error initially as an unpublish request may come through before we've imported the
        # document to begin with.
        logger.warn(sprintf("[GCDE][DELETE %s@v%s] %s", content_id, payload_version, e.message))
      rescue Google::Cloud::Error => e
        logger.error(sprintf("[GCDE][DELETE %s@v%s] %s", content_id, payload_version, e.message))
        GovukError.notify(e)
      end

    private

      attr_reader :datastore_path, :branch_name, :client, :logger

      def branch_path
        "#{datastore_path}/branches/#{branch_name}"
      end

      def document_name(content_id)
        "#{branch_path}/documents/#{content_id}"
      end
    end
  end
end
