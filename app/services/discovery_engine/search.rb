module DiscoveryEngine
  class Search
    DEFAULT_COUNT = 10
    DEFAULT_START = 0

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
  end
end
