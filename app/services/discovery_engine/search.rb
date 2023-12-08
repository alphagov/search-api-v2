module DiscoveryEngine
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
    end

    def result_set
      response = client.search(discovery_engine_params).response

      ResultSet.new(
        results: response.results.map { Result.from_stored_document(_1.document.struct_data.to_h) },
        total: response.total_size,
        start: offset,
      )
    end

  private

    attr_reader :query_params, :client

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

    def serving_config
      Rails.configuration.discovery_engine_serving_config
    end

    def boost_spec
      {
        condition_boost_specs: [
          *Boosts::NewsRecency.new.boost_specs,
          *Boosts::BestBets.new(query).boost_specs,
        ],
      }
    end
  end
end
