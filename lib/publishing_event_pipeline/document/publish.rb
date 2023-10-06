module PublishingEventPipeline
  module Document
    class Publish < Base
      # All the possible keys in the message hash that can contain content that we want to index
      INDEXABLE_CONTENT_VALUES_PATHS = %w[
        $.details.body
        $.details.contact_groups[*].title
        $.details.description
        $.details.hidden_search_terms
        $.details.introduction
        $.details.introductory_paragraph
        $.details.metadata.hidden_indexable_content[*]
        $.details.metadata.project_code
        $.details.more_information
        $.details.need_to_know
        $.details.parts[*]['title','body']
        $.details.summary
        $.details.title
      ].freeze

      include Helpers::Extract

      # Synchronize the document to the given repository (i.e. put it in the repository).
      def synchronize_to(repository)
        repository.put(content_id, metadata, content:, payload_version:)
      end

      # Extracts a hash of structured metadata about this document.
      def metadata
        link = extract_first(document_hash, %w[$.base_path $.details.url])
        url = if link&.start_with?("/")
                Plek.website_root + link
              else
                link
              end
        public_timestamp = extract_single(document_hash, "$.public_updated_at")
        public_timestamp_int = Time.zone.parse(public_timestamp).to_i if public_timestamp

        {
          content_id: extract_single(document_hash, "$.content_id"),
          document_type: extract_single(document_hash, "$.document_type"),
          title: extract_single(document_hash, "$.title"),
          description: extract_single(document_hash, "$.description"),
          link:,
          url:,
          public_timestamp:,
          public_timestamp_int:,
        }
      end

      # Extracts a single string of indexable unstructured content from the document.
      def content
        extract_all(document_hash, INDEXABLE_CONTENT_VALUES_PATHS)
      end
    end
  end
end
