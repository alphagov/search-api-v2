module PublishingEventPipeline
  module Events
    class Publish
      attr_reader :content_id, :metadata, :content, :payload_version

      def initialize(content_id, metadata, content:, payload_version:)
        @content_id = content_id
        @metadata = metadata
        @content = content
        @payload_version = payload_version
      end

      def synchronize_to(repository)
        repository.put(content_id, metadata, content:, payload_version:)
      end
    end
  end
end
