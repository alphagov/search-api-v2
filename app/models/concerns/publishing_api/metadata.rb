module PublishingApi
  module Metadata
    # All the possible keys in the message hash that can contain additional keywords or other text
    # that should be searchable but doesn't form part of the primary document content, represented
    # as JsonPath path strings.
    ADDITIONAL_SEARCHABLE_TEXT_VALUES_JSON_PATHS = %w[
      $.details.acronym
      $.details.attachments[*]['title','isbn','unique_reference','command_paper_number','hoc_paper_number']
      $.details.hidden_search_terms
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
    ].map { JsonPath.new(_1, use_symbols: true) }.freeze
    ADDITIONAL_SEARCHABLE_TEXT_VALUES_SEPARATOR = "\n".freeze

    # Extracts a hash of structured metadata about this document.
    def metadata
      {
        content_id: document_hash[:content_id],
        title: document_hash[:title],
        description: document_hash[:description],
        additional_searchable_text:,
        link:,
        url:,
        public_timestamp:,
        document_type: document_hash[:document_type],
        content_purpose_supergroup: document_hash[:content_purpose_supergroup],
        part_of_taxonomy_tree: document_hash.dig(:links, :taxons) || [],
        # Vertex can only currently boost on numeric fields, not booleans
        is_historic: historic? ? 1 : 0,
        government_name:,
        organisation_state:,
        locale: document_hash[:locale],
        parts:,
      }.compact_blank
    end

    def link
      document_hash[:base_path].presence || document_hash.dig(:details, :url)
    end

  private

    def link_relative?
      link&.start_with?("/")
    end

    def url
      return link unless link_relative?

      Plek.website_root + link
    end

    def additional_searchable_text
      values = ADDITIONAL_SEARCHABLE_TEXT_VALUES_JSON_PATHS.map { _1.on(document_hash) }
      values
        .flatten
        .compact_blank
        .join(ADDITIONAL_SEARCHABLE_TEXT_VALUES_SEPARATOR)
    end

    def public_timestamp
      return nil unless document_hash[:public_updated_at]

      # rubocop:disable Rails/TimeZone (string already contains timezone info which would be lost)
      Time.parse(document_hash[:public_updated_at]).to_i
      # rubocop:enable Rails/TimeZone
    end

    def historic?
      political = document_hash.dig(:details, :political) || false
      government = document_hash.dig(:expanded_links, :government)&.first

      political && government&.dig(:details, :current) == false
    end

    def government_name
      document_hash
        .dig(:expanded_links, :government)
        &.first
        &.dig(:title)
    end

    def organisation_state
      document_hash
        .dig(:details, :organisation_govuk_status, :status)
    end

    def parts
      document_hash
        .dig(:details, :parts)
        &.map do
          {
            slug: _1[:slug],
            title: _1[:title],
            body: BodyContent.new(_1[:body]).summarized_text_content,
          }
        end
    end
  end
end
