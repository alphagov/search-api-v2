module DiscoveryEngine::Autocomplete
  class Complete
    QUERY_MODEL = "user-event".freeze

    def initialize(
      query,
      client: ::Google::Cloud::DiscoveryEngine.completion_service(version: :v1)
    )
      @query = query
      @client = client
    end

    def completion_result
      CompletionResult.new(suggestions:)
    end

  private

    attr_reader :query, :client

    def suggestions
      # Discovery Engine returns an error on an empty query, so we need to handle it ourselves
      return [] if query.blank?

      client
        .complete_query(complete_query_request)
        .query_suggestions
        .map(&:suggestion)
    rescue Google::Cloud::DeadlineExceededError, Google::Cloud::InternalError => e
      Rails.logger.warn("#{self.class.name}: Did not get autocomplete suggestion: '#{e.message}'")
    end

    def complete_query_request
      {
        data_store: DataStore.default.name,
        query:,
        query_model: QUERY_MODEL,
      }
    end
  end
end
