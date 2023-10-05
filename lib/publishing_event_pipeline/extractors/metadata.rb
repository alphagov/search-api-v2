module PublishingEventPipeline
  module Extractors
    class Metadata
      include Helpers::Extract

      def call(message_hash)
        link = extract_first(message_hash, %w[$.base_path $.details.url])
        url = if link&.start_with?("/")
                Plek.website_root + link
              else
                link
              end

        {
          title: extract_single(message_hash, "$.title"),
          description: extract_single(message_hash, "$.description"),
          link:,
          url:,
        }
      end
    end
  end
end
