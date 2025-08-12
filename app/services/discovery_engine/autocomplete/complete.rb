module DiscoveryEngine::Autocomplete
  class Complete
    QUERY_MODEL = "user-event".freeze

    def initialize(query)
      @query = query
    end

    def completion_result
      CompletionResult.new(suggestions:)
    end

  private

    attr_reader :query

    def suggestions
      # Discovery Engine returns an error on an empty query, so we need to handle it ourselves
      return [] if query.blank?

      begin
        response =
          Metrics::Exported.observe_duration(:vertex_autocomplete_request_duration) do
            DiscoveryEngine::Clients
              .completion_service
              .complete_query(complete_query_request)
          end

        response.query_suggestions.map(&:suggestion)
      rescue Google::Cloud::DeadlineExceededError, Google::Cloud::InternalError => e
        Rails.logger.warn("#{self.class.name}: Did not get autocomplete suggestion: '#{e.message}'")

        raise DiscoveryEngine::InternalError
      end
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
