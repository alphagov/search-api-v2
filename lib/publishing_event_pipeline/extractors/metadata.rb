module PublishingEventPipeline
  module Extractors
    class Metadata
      def call(message_hash)
        {
          base_path: message_hash.fetch("base_path"),
        }
      end
    end
  end
end
