module DiscoveryEngine::Query
  UserLabels = Data.define(:consumer, :consumer_group) do
    def self.from_user_agent(user_agent)
      case user_agent.to_s
      when /gds-api-adapters\/.+ \(([^)]+)\)\z/
        # e.g., "gds-api-adapters/99.2.0 (finder-frontend)" -> "finder-frontend"
        new(consumer: Regexp.last_match(1), consumer_group: "web")
      when /\Agovuk_ios\//
        new(consumer: "app-ios", consumer_group: "app")
      when /\Agovuk_android\//
        # NOTE: Android app currently uses the stock `okhttp/` user agent from its HTTP library, but
        # should hopefully change in the future
        new(consumer: "app-android", consumer_group: "app")
      else
        new(consumer: "other", consumer_group: "other")
      end
    end
  end
end
