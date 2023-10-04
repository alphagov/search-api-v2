module PublishingEventPipeline
  module Extractors
    # Extracts single string of indexable unstructured content from a publishing event
    class Content
      include Helpers::Extract

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

      def call(message_hash)
        extract_all(message_hash, INDEXABLE_CONTENT_VALUES_PATHS)
      end
    end
  end
end
