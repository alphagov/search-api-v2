module QualityMonitoring
  class InvariantViolatedError < StandardError; end

  # Ensures that Discovery Engine returns expected results for a set of invariants
  class CheckResultInvariants
    def initialize(search_service_klass: DiscoveryEngine::Query::Search)
      @search_service_klass = search_service_klass
    end

    def violations
      invariants = QualityMonitoring::ResultInvariant.all

      invariants.filter_map { |invariant|
        query_params = { q: invariant.query }
        result_links = search_service_klass.new(query_params).result_set.results.map(&:link)

        missing_links = invariant.expected_links - result_links
        next if missing_links.empty?

        missing_links.map do |missing_link|
          ResultInvariantViolation.new(
            query: invariant.query,
            expected_link: missing_link,
          )
        end
      }.flatten
    end

  private

    attr_reader :search_service_klass
  end
end
