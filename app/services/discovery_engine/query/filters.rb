module DiscoveryEngine::Query
  class Filters
    def initialize(query_params)
      @query_params = query_params
    end

    def filter_expression
      surround_and_join([
        reject_links_filter,
        content_purpose_supergroup_filter,
      ], between: " AND ", surround: "(", surround_end: ")")
    end

  private

    attr_reader :query_params

    def reject_links_filter
      return nil if query_params[:reject_link].blank?

      values = surround_and_join(query_params[:reject_link], between: ",", surround: '"')
      "NOT link: ANY(#{values})"
    end

    def content_purpose_supergroup_filter
      return nil if query_params[:filter_content_purpose_supergroup].blank?

      values = surround_and_join(
        query_params[:filter_content_purpose_supergroup], between: ",", surround: '"'
      )
      "content_purpose_supergroup: ANY(#{values})"
    end

    def surround_and_join(string_or_strings, between:, surround:, surround_end: surround)
      Array(string_or_strings)
        .compact
        .map { "#{surround}#{_1}#{surround_end}" }
        .join(between)
        .presence
    end
  end
end
