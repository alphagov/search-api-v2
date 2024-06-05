module DiscoveryEngine::Sync
  module Versioning
    # Redis key prefix for versions
    VERSION_KEY_PREFIX = "search_api_v2:latest_synced_version".freeze

    def outdated_payload_version?
      # Sense check: This shouldn't ever come through as nil from Publishing API, but if it does,
      # the only really useful thing we can do is ignore this check entirely because we can't
      # meaningfully make a comparison.
      return false if payload_version.nil?

      # If there is no remote version yet, our version is always newer by definition
      return false if latest_synced_version.nil?

      latest_synced_version.to_i >= payload_version.to_i
    end

    # Gets the latest synced version for a document from Redis
    def latest_synced_version
      Rails.application.config.redis_pool.with do |redis|
        redis.get("#{VERSION_KEY_PREFIX}:#{content_id}")&.to_i
      end
    end

    # Sets the latest synced version for a document in Redis
    def set_latest_synced_version
      Rails.application.config.redis_pool.with do |redis|
        redis.set("#{VERSION_KEY_PREFIX}:#{content_id}", payload_version)
      end
    end
  end
end
