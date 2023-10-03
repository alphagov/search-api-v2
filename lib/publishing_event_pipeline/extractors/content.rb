require "jsonpath"

module PublishingEventPipeline
  module Extractors
    # Extracts single string of indexable unstructured content from a publishing event
    class Content
      # JSON paths of keys in the message hash to extract content from
      # (see https://github.com/joshbuddy/jsonpath)
      VALUE_PATHS = %w[
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
        $.details.parts[*].title
        $.details.parts[*].body
        $.details.summary
        $.details.title
      ].map { JsonPath.new(_1) }.freeze

      def call(message_hash)
        VALUE_PATHS
          .map { _1.on(message_hash) }
          .flatten
          .join("\n")
      end
    end
  end
end
