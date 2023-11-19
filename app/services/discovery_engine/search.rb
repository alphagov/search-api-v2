module DiscoveryEngine
  class Search
    DEFAULT_COUNT = 10
    DEFAULT_START = 0

    include BestBetsBoost
    include NewsRecencyBoost

    def initialize(client: ::Google::Cloud::DiscoveryEngine.search_service(version: :v1))
      @client = client
    end

    def call(query_string, start: nil, count: nil)
      count ||= DEFAULT_COUNT
      start ||= DEFAULT_START

      response = client.search(
        query: query_string,
        serving_config:,
        page_size: count,
        offset: start,
        boost_spec: boost_spec(query_string),
      ).response

      ResultSet.new(
        results: response.results.map { Result.from_stored_document(_1.document.struct_data.to_h) },
        total: response.total_size,
        start:,
      )
    end

  private

    attr_reader :client

    def serving_config
      Rails.configuration.discovery_engine_serving_config
    end

    def boost_spec(query_string)
      {
        condition_boost_specs: [
          *news_recency_boost_specs,
          *best_bets_boost_specs(query_string),
        ],
      }
    end
  end
end
