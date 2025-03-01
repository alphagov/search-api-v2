module DiscoveryEngine::Query
  module FilterExpressionHelpers
    TIMESTAMP_VALUE_REGEX = /\A(?:from:(?<from>\d{4}-\d{2}-\d{2}))?(?:,)?(?:to:(?<to>\d{4}-\d{2}-\d{2}))?\z/

    # Creates a filter expression for documents where string_or_array_field contains any of the
    # values in string_value_or_values
    def filter_any_string(string_or_array_field, string_value_or_values)
      Array(string_value_or_values)
        .map { quote(_1) }
        .join(",")
        .then { "#{string_or_array_field}: ANY(#{_1})" }
    end

    # Creates a filter expression for documents where array_field contains all of the values in string_value_or_values
    def filter_all_string(array_field, string_value_or_values)
      Array(string_value_or_values)
        .map { filter_any_string(array_field, _1) }
        .then { filter_conjunction(_1) }
    end

    # Creates a filter expression for documents where string_or_array_field does not contain any of the values in
    # string_value_or_values
    def filter_not_string(string_or_array_field, string_value_or_values)
      filter_any_string(string_or_array_field, string_value_or_values)
        .then { filter_negate(_1) }
    end

    # Creates a filter expression for documents where timestamp_field is between the dates in
    # timestamp_value
    def filter_timestamp(timestamp_field, timestamp_value)
      match = timestamp_value.match(TIMESTAMP_VALUE_REGEX)
      unless match && (match[:from] || match[:to])
        Rails.logger.warn("#{self.class.name}: Invalid timestamp value: '#{timestamp_value}'")
        return nil
      end

      from = match[:from] ? Date.parse(match[:from]).beginning_of_day.to_i : "*"
      to = match[:to] ? Date.parse(match[:to]).end_of_day.to_i : "*"

      # Finder Frontend does not validate that the from date is before the to date, so we need to
      # handle this case gracefully because Discovery Engine will return an error. The easiest way
      # to do this is to just swap the dates if they are in the wrong order.
      if match[:from] && match[:to] && from > to
        from = Date.parse(match[:to]).beginning_of_day.to_i
        to = Date.parse(match[:from]).end_of_day.to_i
      end

      "#{timestamp_field}: IN(#{from},#{to})"
    end

    # Creates a filter expression from several expressions where all must be true
    def filter_conjunction(expression_or_expressions)
      expressions = Array(expression_or_expressions).compact_blank
      return expressions.first if expressions.one?

      Array(expressions)
        .map { parenthesize(_1) }
        .join(" AND ")
        .presence
    end

  private

    def filter_negate(expression)
      "NOT #{expression}"
    end

    def parenthesize(expression)
      "(#{expression})"
    end

    def quote(string_value)
      "\"#{string_value}\""
    end
  end
end
