module DiscoveryEngine::Query
  class Filters
    def initialize(query_params)
      @query_params = query_params
    end

    def filter_expression
      expressions = [
        reject_links_filter,
        content_purpose_supergroup_filter,
      ]

      expressions
        .compact
        .map { surround(_1, delimiter: "(", delimiter_end: ")") }
        .join(" AND ")
        .presence
    end

  private

    attr_reader :query_params

    def reject_links_filter
      return nil if query_params[:reject_link].blank?

      values = Array(query_params[:reject_link])
        .map { filter_string_value(_1) }
        .join(",")

      "NOT link: ANY(#{values})"
    end

    def content_purpose_supergroup_filter
      return nil if query_params[:filter_content_purpose_supergroup].blank?

      values = Array(query_params[:filter_content_purpose_supergroup])
        .map { filter_string_value(_1) }
        .join(",")

      "content_purpose_supergroup: ANY(#{values})"
    end

    # Input strings need to be wrapped in double quotes and have double quotes or backslashes
    # escaped for Discovery Engine's filter syntax
    def filter_string_value(str)
      escaped_str = str.gsub(/(["\\])/, '\\\\\1')
      surround(escaped_str, delimiter: '"')
    end

    def surround(str, delimiter:, delimiter_end: delimiter)
      "#{delimiter}#{str}#{delimiter_end}"
    end
  end
end
