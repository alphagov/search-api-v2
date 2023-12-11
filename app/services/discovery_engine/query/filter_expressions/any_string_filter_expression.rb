module DiscoveryEngine::Query::FilterExpressions
  class AnyStringFilterExpression < StringFilterExpression
    def expression
      return if values.empty?

      "#{field}: ANY(#{values.join(',')})"
    end
  end
end
