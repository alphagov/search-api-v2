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
        public_timestamp = extract_single(message_hash, "$.public_updated_at")
        public_timestamp_int = Time.zone.parse(public_timestamp).to_i if public_timestamp

        {
          content_id: extract_single(message_hash, "$.content_id"),
          document_type: extract_single(message_hash, "$.document_type"),
          title: extract_single(message_hash, "$.title"),
          description: extract_single(message_hash, "$.description"),
          link:,
          url:,
          public_timestamp:,
          public_timestamp_int:,
        }
      end
    end
  end
end
