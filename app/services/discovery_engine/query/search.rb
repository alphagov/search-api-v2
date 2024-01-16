module DiscoveryEngine::Query
  class Search
    DEFAULT_PAGE_SIZE = 10
    DEFAULT_OFFSET = 0
    DEFAULT_ORDER_BY = nil # not specifying an order_by means the results are ordered by relevance

    def initialize(
      query_params,
      client: ::Google::Cloud::DiscoveryEngine.search_service(version: :v1)
    )
      @query_params = query_params
      @client = client

      Rails.logger.debug { "Instantiated #{self.class.name}: Query: #{discovery_engine_params}" }
    end

    def result_set
      ResultSet.new(
        results: response.results.map { Result.from_stored_document(_1.document.struct_data.to_h) },
        total: response.total_size,
        start: offset,
        suggested_queries:,
        discovery_engine_attribution_token: response.attribution_token,
      )
    end

  private

    attr_reader :query_params, :client

    def response
      @response ||= begin
        Metrics.increment_counter(:search_requests)
        client.search(discovery_engine_params).response
      end
    end

    def discovery_engine_params
      {
        query:,
        serving_config:,
        page_size:,
        offset:,
        order_by:,
        filter:,
        boost_spec:,
      }.compact
    end

    def query
      query_params[:q].presence || ""
    end

    def serving_config
      Rails.configuration.discovery_engine_serving_config
    end

    def page_size
      query_params[:count].presence&.to_i || DEFAULT_PAGE_SIZE
    end

    def offset
      query_params[:start].presence&.to_i || DEFAULT_OFFSET
    end

    def order_by
      case query_params[:order].presence
      when "public_timestamp"
        "public_timestamp"
      when "-public_timestamp"
        "public_timestamp desc"
      when nil, "relevance", "popularity"
        # "relevance" and "popularity" behave differently on the previous search-api, but we can
        # treat them the same with Discovery Engine (as empty searches will default to a
        # popularity-ish order anyway and we don't have an explicit popularity option available).
        DEFAULT_ORDER_BY
      else
        # This helps us spot clients that are sending unexpected values and probably should continue
        # to use the previoius search-api instead of this API.
        Rails.logger.warn("Unexpected order_by value: #{query_params[:order].inspect}")
        DEFAULT_ORDER_BY
      end
    end

    def filter
      Filters.new(query_params).filter_expression
    end

    def boost_spec
      {
        condition_boost_specs: [
          *NewsRecencyBoost.new.boost_specs,
          *BestBetsBoost.new(query).boost_specs,
        ],
      }
    end

    def suggested_queries
      # TODO: Highlighting isn't actually supported by Discovery Engine, and this _always_ returns a
      # single suggestion, but we need to do this for API compatibility with Finder Frontend.
      # Eventually this should be improved.
      return [] unless query_params[:suggest] == "spelling_with_highlighting"

      # Gotcha: Discovery Engine returns an empty string rather than null if there is no correction.
      return [] if response.corrected_query.blank?

      [{
        text: response.corrected_query,
        highlighted: "<mark>#{response.corrected_query}</mark>",
      }]
    end
  end
end
