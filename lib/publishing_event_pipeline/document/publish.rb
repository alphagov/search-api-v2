module PublishingEventPipeline
  module Document
    class Publish < Base
      # All the possible keys in the message hash that can contain unstructured content that we want
      # to index, represented as JsonPath path strings.
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
      INDEXABLE_CONTENT_SEPARATOR = "\n".freeze

      # Synchronize the document to the given repository (i.e. put it in the repository).
      def synchronize_to(repository)
        repository.put(content_id, metadata, content:, payload_version:)
      end

      # Extracts a hash of structured metadata about this document.
      def metadata
        {
          content_id: document_hash["content_id"],
          document_type: document_hash["document_type"],
          title: document_hash["title"],
          description: document_hash["description"],
          link:,
          url:,
          public_timestamp:,
          public_timestamp_int:,
        }
      end

      # Extracts a single string of indexable unstructured content from the document.
      def content
        values = INDEXABLE_CONTENT_VALUES_PATHS.map { JsonPath.new(_1).on(document_hash) }
        values.flatten.join(INDEXABLE_CONTENT_SEPARATOR)
      end

    private

      def link
        document_hash["base_path"].presence || document_hash.dig("details", "url")
      end

      def link_relative?
        link&.start_with?("/")
      end

      def url
        return link unless link_relative?

        Plek.website_root + link
      end

      def public_timestamp
        document_hash["public_updated_at"]
      end

      def public_timestamp_int
        return nil unless public_timestamp

        Time.zone.parse(public_timestamp).to_i
      end
    end
  end
end
