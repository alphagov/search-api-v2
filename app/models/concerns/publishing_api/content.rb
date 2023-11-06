module PublishingApi
  module Content
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
    ].map { JsonPath.new(_1, use_symbols: true) }.freeze
    INDEXABLE_CONTENT_SEPARATOR = "\n".freeze
    INDEXABLE_CONTENT_MAX_BYTE_SIZE = 950.kilobytes

    # Extracts a single string of indexable unstructured content from the document.
    def content
      values_from_json_paths = INDEXABLE_CONTENT_VALUES_JSON_PATHS.map { _1.on(document_hash) }
      values_from_parts = document_hash.dig(:details, :parts)&.map do
        # Add the part title as a heading to help the search model better understand the structure
        # of the content
        ["<h1>#{_1[:title]}</h1>", ContentWithMultipleTypes.new(_1[:body]).html_content]
      end

      [*values_from_json_paths, *values_from_parts]
        .flatten
        .join(INDEXABLE_CONTENT_SEPARATOR)
        # Only take the first INDEXABLE_CONTENT_MAX_BYTE_SIZE bytes of the string
        .byteslice(0, INDEXABLE_CONTENT_MAX_BYTE_SIZE)
        # Remove any trailing invalid UTF-8 characters that might have been introduced through
        # slicing the string
        .scrub("")
    end
  end
end
