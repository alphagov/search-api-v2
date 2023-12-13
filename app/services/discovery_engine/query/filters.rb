module DiscoveryEngine::Query
  class Filters
    FILTERABLE_FIELDS = %i[content_purpose_supergroup link part_of_taxonomy_tree].freeze

    include FilterExpressionHelpers

    def initialize(query_params)
      @query_params = query_params
    end

    def filter_expression
      expressions = [
        *query_params_of_type(:reject).map { not_string(_1, _2) },
        *query_params_of_type(:filter).map { any_string(_1, _2) },
        *query_params_of_type(:filter_all).map { all_string(_1, _2) },
      ].compact

      conjunction(expressions)
    end

  private

    attr_reader :query_params

    def query_params_of_type(type)
      FILTERABLE_FIELDS
        .filter_map { [_1, query_params["#{type}_#{_1}".to_sym]] }
        .to_h
        .compact_blank
    end
  end
end
