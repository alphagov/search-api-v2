module DiscoveryEngine::Query::FilterExpressions
  class StringFilterExpression
    def initialize(field, value_or_values)
      @field = field
      @values = Array(value_or_values).compact_blank.map { StringValue.new(_1) }
    end

    def negated_expression
      "NOT #{expression}"
    end

  private

    attr_reader :field, :values
  end
end
