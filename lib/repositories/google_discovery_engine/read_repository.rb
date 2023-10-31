require "google/cloud/discovery_engine"

module Repositories
  module GoogleDiscoveryEngine
    # A repository to search Google Discovery Engine
    class ReadRepository
      SearchResults = Data.define(:results, :total)

      DEFAULT_START = 0
      DEFAULT_COUNT = 0

      def initialize(
        serving_config_path = Rails.configuration.discovery_engine_serving_config,
        client: ::Google::Cloud::DiscoveryEngine.search_service(version: :v1),
        logger: Logger.new($stdout, progname: self.class.name)
      )
        @serving_config_path = serving_config_path
        @client = client
        @logger = logger
      end

      def search(query_string, start: DEFAULT_START, count: DEFAULT_COUNT)
        response = client.search(
          query: query_string,
          serving_config: serving_config_path,
          page_size: count,
          offset: start,
        ).response

        SearchResults.new(
          results: response.results.map { _1.document.struct_data.to_h },
          total: response.total_size,
        )
      end

    private

      attr_reader :client, :serving_config_path, :logger
    end
  end
end
