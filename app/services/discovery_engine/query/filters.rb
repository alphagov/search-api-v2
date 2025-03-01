module DiscoveryEngine::Query
  class Filters
    FILTER_PARAM_KEY_REGEX = /\A(filter_all|filter|reject)_(.+)\z/
    ACCEPTABLE_VALUE_REGEX = /\A[a-zA-Z0-9_:,\-\/]+\z/

    FILTERABLE_STRING_FIELDS = %w[
      content_purpose_supergroup
      link
      manual
      organisations
      part_of_taxonomy_tree
      topical_events
      world_locations
    ].freeze
    FILTERABLE_TIMESTAMP_FIELDS = %w[public_timestamp].freeze

    include FilterExpressionHelpers

    def initialize(query_params)
      @query_params = query_params.to_h
    end

    def filter_expression
      query_params
        .map { parse_param(_1, _2) }
        .compact_blank
        .then { filter_conjunction(_1) }
    end

  private

    attr_reader :query_params

    def parse_param(key, value)
      filter_type, filter_field = key.match(FILTER_PARAM_KEY_REGEX)&.captures
      return nil unless filter_type && value.present?
      return nil unless valid_filter_value?(value)

      case filter_field
      when *FILTERABLE_STRING_FIELDS
        string_filter_expression(filter_type, filter_field, value)
      when *FILTERABLE_TIMESTAMP_FIELDS
        if filter_type != "filter"
          Rails.logger.warn(
            "#{self.class.name}: Cannot filter on timestamp field '#{filter_field}' " \
            "with filter type '#{filter_type}'",
          )
          return nil
        end

        filter_timestamp(filter_field, value)
      else
        Rails.logger.info("#{self.class.name}: Ignoring unknown filter field: '#{filter_field}'")
        nil
      end
    end

    def string_filter_expression(filter_type, filter_field, value)
      case filter_type
      when "filter"
        filter_any_string(filter_field, value)
      when "filter_all"
        filter_all_string(filter_field, value)
      when "reject"
        filter_not_string(filter_field, value)
      end
    end

    def valid_filter_value?(value)
      # Finder Frontend should be more resilient to invalid filter values, but we can't rely on that
      # for the time being. This ensures that occasionally observed garbage parameters such as:
      #
      #   filter_world_locations[\\\\]=all
      #   filter_something=blah%00blah
      #
      # are ignored by checking that the value is either a string or an array of strings, and
      # matches an allowlist of permissible characters.
      Array(value).all? { _1.is_a?(String) && _1.match?(ACCEPTABLE_VALUE_REGEX) }
    end
  end
end
