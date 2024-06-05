module Coordination
  # Keeps track of the latest version of a document that has been synced. This allows us to avoid
  # race conditions where an older document version is processed after a newer one.
  class DocumentVersionCache
    # Redis key prefix for versions
    VERSION_KEY_PREFIX = "search_api_v2:latest_synced_version".freeze

    def initialize(content_id, payload_version:)
      @content_id = content_id
      @payload_version = payload_version
    end

    # Checks whether this document version is outdated (because the cache tracks a newer version).
    def outdated?
      # Sense check: This shouldn't ever come through as nil from Publishing API, but if it does,
      # the only really useful thing we can do is ignore this check entirely because we can't
      # meaningfully make a comparison.
      return false if payload_version.nil?

      # If there is no remote version yet, our version is always newer by definition
      return false if latest_synced_version.nil?

      latest_synced_version.to_i >= payload_version.to_i
    end

  private

    attr_reader :content_id, :payload_version

    def latest_synced_version
      Rails.application.config.redis_pool.with do |redis|
        redis.get("#{VERSION_KEY_PREFIX}:#{content_id}")&.to_i
      end
    end
  end
end
