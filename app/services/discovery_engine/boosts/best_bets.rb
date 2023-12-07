module DiscoveryEngine::Boosts
  class BestBets
    def initialize(query_string)
      @query_string = query_string
    end

    def boost_specs
      return unless best_bets_for_query.any?

      [{
        boost: 1,
        condition: "link: ANY(#{condition_links})",
      }]
    end

  private

    attr_reader :query_string

    def best_bets_for_query
      Array(Rails.configuration.best_bets[query_string])
    end

    def condition_links
      best_bets_for_query.map { "\"#{_1}\"" }.join(",")
    end
  end
end
