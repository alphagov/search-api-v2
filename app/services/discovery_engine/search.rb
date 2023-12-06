module DiscoveryEngine
  class Search
    DEFAULT_PAGE_SIZE = 10
    DEFAULT_OFFSET = 0

    include BestBetsBoost
    include NewsRecencyBoost

    def initialize(
      query_params,
      client: ::Google::Cloud::DiscoveryEngine.search_service(version: :v1)
    )
      @query_params = query_params
      @client = client
    end

    def result_set
      response = client.search(
        query:,
        serving_config:,
        page_size:,
        offset:,
        boost_spec:,
      ).response

      ResultSet.new(
        results: response.results.map { Result.from_stored_document(_1.document.struct_data.to_h) },
        total: response.total_size,
        start: offset,
      )
    end

  private

    attr_reader :query_params, :client

    def query
      query_params[:q].presence || ""
    end

    def page_size
      query_params[:count].presence&.to_i || DEFAULT_PAGE_SIZE
    end

    def offset
      query_params[:start].presence&.to_i || DEFAULT_OFFSET
    end

    def serving_config
      Rails.configuration.discovery_engine_serving_config
    end

    def boost_spec
      {
        condition_boost_specs: [
          *news_recency_boost_specs,
          *best_bets_boost_specs(query),
        ],
      }
    end
  end
end
