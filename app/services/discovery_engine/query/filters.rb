module DiscoveryEngine::Query
  class Filters
    FILTERABLE_FIELDS = %i[content_purpose_supergroup link part_of_taxonomy_tree].freeze

    def initialize(query_params)
      @query_params = query_params
    end

    def filter_expression
      expressions = [
        *query_params_of_type(:reject).map { reject_filter(_1, _2) },
        *query_params_of_type(:filter).map { any_filter(_1, _2) },
        *query_params_of_type(:filter_all).map { all_filter(_1, _2) },
      ].compact

      expressions
        .map { "(#{_1})" }
        .join(" AND ")
        .presence
    end

  private

    attr_reader :query_params

    def query_params_of_type(type)
      FILTERABLE_FIELDS
        .filter_map { [_1, query_params["#{type}_#{_1}".to_sym]] }
        .to_h
        .compact_blank
    end

    def reject_filter(field, value_or_values)
      string_filter_expression(field, value_or_values, negate: true)
    end

    def all_filter(field, value_or_values)
      Array(value_or_values)
        .map { string_filter_expression(field, _1) }
        .join(" AND ")
        .presence
    end

    def any_filter(field, value_or_values)
      string_filter_expression(field, value_or_values)
    end

    def string_filter_expression(field, value_or_values, negate: false)
      values = Array(value_or_values).map { FilterExpressions::StringValue.new(_1) }
      return if values.blank?

      "#{negate ? 'NOT ' : ''}#{field}: ANY(#{values.join(',')})"
    end
  end
end
