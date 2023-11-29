module PublishingApi
  module Content
    # All the possible keys in the message hash that can contain the primary unstructured document
    # content that we want to index, represented as JsonPath path strings.
    INDEXABLE_CONTENT_VALUES_JSON_PATHS = %w[
      $.details.acronym
      $.details.attachments[*]['title','isbn','unique_reference','command_paper_number','hoc_paper_number']
      $.details.body
      $.details.contact_groups[*].title
      $.details.description
      $.details.hidden_search_terms
      $.details.introduction
      $.details.introductory_paragraph
      $.details.licence_short_description
      $.details.metadata.aircraft_type
      $.details.metadata.authors
      $.details.metadata.business_sizes
      $.details.metadata.business_stages
      $.details.metadata.hidden_indexable_content
      $.details.metadata.industries
      $.details.metadata.keyword
      $.details.metadata.licence_transaction_industry
      $.details.metadata.project_code
      $.details.metadata.reference_number
      $.details.metadata.regions
      $.details.metadata.registration
      $.details.metadata.research_document_type
      $.details.metadata.result
      $.details.metadata.stage
      $.details.metadata.theme
      $.details.metadata.tribunal_decision_categories_name
      $.details.metadata.tribunal_decision_category_name
      $.details.metadata.tribunal_decision_country_name
      $.details.metadata.tribunal_decision_judges_name
      $.details.metadata.tribunal_decision_landmark_name
      $.details.metadata.tribunal_decision_sub_categories_name
      $.details.metadata.tribunal_decision_sub_category_name
      $.details.metadata.types_of_support
      $.details.metadata.virus_strain
      $.details.metadata.year_adopted
      $.details.more_information
      $.details.need_to_know
      $.details.summary
      $.details.title
    ].map { JsonPath.new(_1, use_symbols: true) }.freeze
    INDEXABLE_CONTENT_SEPARATOR = "\n".freeze

    # Extracts a single string of indexable unstructured content from the document.
    def content
      values_from_json_paths = INDEXABLE_CONTENT_VALUES_JSON_PATHS.map do |item|
        item.on(document_hash).map { |body| BodyContent.new(body).html_content }
      end
      values_from_parts = document_hash.dig(:details, :parts)&.map do |part|
        # Add the part title as a heading to help the search model better understand the structure
        # of the content
        ["<h1>#{part[:title]}</h1>", BodyContent.new(part[:body]).html_content]
      end

      [*values_from_json_paths, *values_from_parts]
        .flatten
        .compact_blank
        .join(INDEXABLE_CONTENT_SEPARATOR)
    end
  end
end
