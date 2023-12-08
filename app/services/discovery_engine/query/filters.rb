module DiscoveryEngine::Query
  class Filters
    def initialize(query_params)
      @query_params = query_params
    end

    def filter_expression
      reject_links_filter
    end

  private

    attr_reader :query_params

    def reject_links_filter
      return nil if query_params[:reject_link].blank?

      reject_links = Array(query_params[:reject_link]).map { "\"#{_1}\"" }.join(",")
      "NOT link: ANY(#{reject_links})"
    end
  end
end
