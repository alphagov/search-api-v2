module DiscoveryEngine::Query
  module FilterExpressionHelpers
    # Creates a filter expression for documents where string_or_array_field contains any of the
    # values in string_value_or_values
    def any_string(string_or_array_field, string_value_or_values)
      Array(string_value_or_values)
        .map { escape_and_quote(_1) }
        .join(",")
        .then { "#{string_or_array_field}: ANY(#{_1})" }
    end

    # Creates a filter expression for documents where array_field contains all of the values in string_value_or_values
    def all_string(array_field, string_value_or_values)
      Array(string_value_or_values)
        .map { any_string(array_field, _1) }
        .then { conjunction(_1) }
    end

    # Creates a filter expression for documents where string_or_array_field does not contain any of the values in
    # string_value_or_values
    def not_string(string_or_array_field, string_value_or_values)
      any_string(string_or_array_field, string_value_or_values)
        .then { negate(_1) }
    end

    # Creates a filter expression from several expressions where all must be true
    def conjunction(expression_or_expressions)
      expressions = Array(expression_or_expressions).compact_blank
      return expressions.first if expressions.one?

      Array(expressions)
        .map { parenthesize(_1) }
        .join(" AND ")
        .presence
    end

  private

    def negate(expression)
      "NOT #{expression}"
    end

    def parenthesize(expression)
      "(#{expression})"
    end

    def escape_and_quote(string_value)
      escaped_string = string_value.gsub(/(["\\])/, '\\\\\1')
      "\"#{escaped_string}\""
    end
  end
end
