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

    # The limit of content length on Discovery Engine API is currently 500KB, so we need to truncate
    # the content to a reasonable size.
    #
    # TODO: Try and get limit increased?
    INDEXABLE_CONTENT_MAX_BYTE_SIZE = 480.kilobytes

    # Extracts a single string of indexable unstructured content from the document.
    def content
      values_from_json_paths = INDEXABLE_CONTENT_VALUES_JSON_PATHS.map { _1.on(document_hash) }
      values_from_parts = document_hash.dig(:details, :parts)&.map do
        # Add the part title as a heading to help the search model better understand the structure
        # of the content
        ["<h1>#{_1[:title]}</h1>", BodyContent.new(_1[:body]).html_content]
      end

      [*values_from_json_paths, *values_from_parts]
        .flatten
        .join(INDEXABLE_CONTENT_SEPARATOR)
        .truncate_bytes(INDEXABLE_CONTENT_MAX_BYTE_SIZE)
    end
  end
end
