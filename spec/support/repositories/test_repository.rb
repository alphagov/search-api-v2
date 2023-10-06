module DocumentSyncWorker
  module Repositories
    # A fake repository for end-to-end testing purposes
    class TestRepository
      attr_reader :documents

      def initialize(documents = {})
        @documents = documents
      end

      def exists?(content_id)
        documents.key?(content_id)
      end

      def get(content_id)
        documents[content_id]
      end

      # rubocop:disable Lint/UnusedMethodArgument
      def put(content_id, metadata, content: nil, payload_version: nil)
        documents[content_id] = { metadata:, content: }
      end

      def delete(content_id, payload_version: nil)
        documents.delete(content_id)
      end
      # rubocop:enable Lint/UnusedMethodArgument
    end
  end
end
