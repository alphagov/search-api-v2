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

    # Checks whether this document should be synced based on the current payload version and the
    # latest synced version in the cache (if any).
    def sync_required?
      # Sense check: This shouldn't ever come through as nil from Publishing API, but if it does,
      # the only really useful thing we can do is ignore this check entirely because we can't
      # meaningfully make a comparison.
      return true if payload_version.nil?

      # If there is no remote version yet (or the cache has expired), we always want to sync.
      return true if latest_synced_version.nil?

      payload_version.to_i > latest_synced_version.to_i
    end

    # Sets the latest synced version to the current payload version, for example after a successful
    # sync operation.
    #
    # Note that this method should only be called when holding a lock on the document through
    # `DocumentLock` as it does not guarantee any locking of its own.
    def set_as_latest_synced_version
      Rails.application.config.redis_pool.with do |redis|
        redis.set("#{VERSION_KEY_PREFIX}:#{content_id}", payload_version)
      end
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
