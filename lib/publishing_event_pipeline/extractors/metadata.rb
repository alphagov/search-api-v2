module PublishingEventPipeline
  module Extractors
    class Metadata
      include Helpers::Extract

      def call(message_hash)
        {
          title: extract_single(message_hash, "$.title"),
          description: extract_single(message_hash, "$.description"),
          link: extract_first(message_hash, %w[$.base_path $.details.url]),
        }
      end
    end
  end
end
