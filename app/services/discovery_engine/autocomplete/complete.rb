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
        suggestions = response.query_suggestions.map(&:suggestion)
        Rails.logger.warn("Completion service did not return any autocomplete suggestions") if suggestions.nil?
      rescue Google::Cloud::DeadlineExceededError, Google::Cloud::InternalError => e
        Rails.logger.warn("#{self.class.name}: Did not get autocomplete suggestion: '#{e.message}'")
        suggestions = []
      end

      Metrics::Exported.observe_count(:discovery_engine_autocomplete_suggestions_response, suggestions.size)
      suggestions
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
