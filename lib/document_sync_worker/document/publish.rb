module DocumentSyncWorker
  module Document
    class Publish < Base
      # All the possible keys in the message hash that can contain the primary unstructured document
      # content that we want to index, represented as JsonPath path strings.
      INDEXABLE_CONTENT_VALUES_JSON_PATHS = %w[
        $.details.description
        $.details.introduction
        $.details.introductory_paragraph
        $.details.contact_groups[*].title
        $.details.title
        $.details.summary
        $.details.body
        $.details.need_to_know
        $.details.more_information
      ].map { JsonPath.new(_1) }.freeze
      INDEXABLE_CONTENT_SEPARATOR = "\n".freeze

      # All the possible keys in the message hash that can contain additional keywords or other text
      # that should be searchable but doesn't form part of the primary document content, represented
      # as JsonPath path strings.
      ADDITIONAL_SEARCHABLE_TEXT_VALUES_JSON_PATHS = %w[
        $.details.hidden_search_terms
        $.details.metadata.hidden_indexable_content
        $.details.metadata.project_code
      ].map { JsonPath.new(_1) }.freeze
      ADDITIONAL_SEARCHABLE_TEXT_VALUES_SEPARATOR = "\n".freeze

      # Synchronize the document to the given repository (i.e. put it in the repository).
      def synchronize_to(repository)
        repository.put(content_id, metadata, content:, payload_version:)
      end

      # Extracts a hash of structured metadata about this document.
      def metadata
        {
          content_id: document_hash["content_id"],
          title: document_hash["title"],
          description: document_hash["description"],
          additional_searchable_text:,
          link:,
          url:,
          public_timestamp:,
          document_type: document_hash["document_type"],
          content_purpose_supergroup: document_hash["content_purpose_supergroup"],
          part_of_taxonomy_tree: document_hash.dig("links", "taxons") || [],
          # Vertex can only currently boost on numeric fields, not booleans
          is_historic: historic? ? 1 : 0,
          locale: document_hash["locale"],
          parts:,
        }
      end

      # Extracts a single string of indexable unstructured content from the document.
      def content
        values = INDEXABLE_CONTENT_VALUES_JSON_PATHS.map { _1.on(document_hash) }
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

      def additional_searchable_text
        values = ADDITIONAL_SEARCHABLE_TEXT_VALUES_JSON_PATHS.map { _1.on(document_hash) }
        values.flatten.join(ADDITIONAL_SEARCHABLE_TEXT_VALUES_SEPARATOR)
      end

      def public_timestamp
        return nil unless document_hash["public_updated_at"]

        # rubocop:disable Rails/TimeZone (string already contains timezone info which would be lost)
        Time.parse(document_hash["public_updated_at"]).to_i
        # rubocop:enable Rails/TimeZone
      end

      def historic?
        political = document_hash.dig("details", "political") || false
        government = document_hash.dig("expanded_links", "government")&.first

        political && government&.dig("details", "current") == false
      end

      def parts
        document_hash
          .dig("details", "parts")
          &.map do
            {
              slug: _1["slug"],
              title: _1["title"],
              body: ContentWithMultipleTypes.new(_1["body"]).summarized_text_content,
            }
          end
      end
    end
  end
end
