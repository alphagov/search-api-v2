module DiscoveryEngine
  module BestBetsBoost
    def best_bets_boost_specs(query_string)
      best_bets_for_query = Array(Rails.configuration.best_bets[query_string])
      return unless best_bets_for_query.any?

      condition_links = best_bets_for_query.map { "\"#{_1}\"" }.join(",")
      [{
        boost: 1,
        condition: "link: ANY(#{condition_links})",
      }]
    end
  end
end
