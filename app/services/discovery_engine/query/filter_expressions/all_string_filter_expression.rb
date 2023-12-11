module DiscoveryEngine::Query::FilterExpressions
  class AllStringFilterExpression < StringFilterExpression
    def expression
      return if values.empty?

      # There is no `ALL` equivalent for `ANY` in Discovery Engine, so we need to join up multiple
      # `ANY` expressions to achieve the same effect.
      values.map { "#{field}: ANY(#{_1})" }.join(" AND ")
    end
  end
end
