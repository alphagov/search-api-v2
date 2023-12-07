module DiscoveryEngine::Boosts
  class NewsRecency
    FRESH_AGE = 1.week
    RECENT_AGE = 3.months
    OLD_AGE = 1.year
    ANCIENT_AGE = 4.years

    def boost_specs
      [
        {
          boost: 0.2,
          condition: news_boost_condition("#{FRESH_AGE.ago.to_i}i,*"),
        },
        {
          boost: 0.05,
          condition: news_boost_condition("#{RECENT_AGE.ago.to_i}i,#{FRESH_AGE.ago.to_i}e"),
        },
        {
          boost: -0.5,
          condition: news_boost_condition("#{ANCIENT_AGE.ago.to_i}i,#{OLD_AGE.ago.to_i}e"),
        },
        {
          boost: -0.75,
          condition: news_boost_condition("*,#{ANCIENT_AGE.ago.to_i}e"),
        },
      ]
    end

  private

    def news_boost_condition(timeframe_in)
      "content_purpose_supergroup: ANY(\"news_and_communications\")"\
        " AND public_timestamp: IN(#{timeframe_in})"
    end
  end
end
