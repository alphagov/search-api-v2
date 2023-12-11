module DiscoveryEngine::Query
  class Filters
    FILTERABLE_FIELDS = %i[content_purpose_supergroup link part_of_taxonomy_tree].freeze

    def initialize(query_params)
      @query_params = query_params
    end

    def filter_expression
      expressions = [
        *query_params_of_type(:reject).map { FilterExpressions::AnyStringFilterExpression.new(_1, _2).negated_expression },
        *query_params_of_type(:filter).map { FilterExpressions::AnyStringFilterExpression.new(_1, _2).expression },
        *query_params_of_type(:filter_all).map { FilterExpressions::AllStringFilterExpression.new(_1, _2).expression },
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
  end
end
