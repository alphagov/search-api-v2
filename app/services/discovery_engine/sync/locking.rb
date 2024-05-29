module DiscoveryEngine::Sync
  # Mixin providing a mechanism for sync operations (`Put`, `Delete`) to lock documents while they
  # are being operated on so that other workers cannot simultaneously update the same document.
  module Locking
    # Redis key prefix for locks and versions
    LOCK_KEY_PREFIX = "search_api_v2:sync_lock".freeze
    VERSION_KEY_PREFIX = "search_api_v2:latest_synced_version".freeze

    # Time-to-live for document locks if not explicitly released
    DOCUMENT_LOCK_TTL = 30.seconds.in_milliseconds

    # Options for Redlock client around handling retries
    RETRY_COUNT = 10
    RETRY_DELAY = 5.seconds.in_milliseconds
    RETRY_JITTER = 5.seconds.in_milliseconds

    # Locks a document while a critical section block is executed to avoid multiple workers
    # competing to update the same document.
    def with_locked_document(&critical_section)
      redlock_client.lock!(
        "#{LOCK_KEY_PREFIX}:#{content_id}",
        DOCUMENT_LOCK_TTL,
      ) do
        Rails.logger.add(
          Logger::Severity::INFO,
          "[#{self.class.name}] Lock acquired for document: #{content_id}, " \
            "payload_version: #{payload_version}",
        )

        critical_section.call

        Rails.logger.add(
          Logger::Severity::INFO,
          "[#{self.class.name}] Releasing lock for document: #{content_id}, " \
            "payload_version: #{payload_version}",
        )
      end
    rescue Redlock::LockError => e
      # This should be a very rare occurrence (for example, if/when Redis is down). Our "least
      # worst" fallback option is to perform the action anyway without the lock (which is the
      # previous behaviour from before we had this locking mechanism).
      Rails.logger.add(
        Logger::Severity::ERROR,
        "[#{self.class.name}] Failed to acquire lock for document: #{content_id}, " \
          "payload_version: #{payload_version}. Continuing without lock.",
      )
      GovukError.notify(e)

      critical_section.call
    end

    def outdated_payload_version?(content_id, payload_version:)
      # Sense check: This shouldn't ever come through as nil from Publishing API, but if it does,
      # the only really useful thing we can do is ignore this check entirely because we can't
      # meaningfully make a comparison.
      return false if payload_version.nil?

      # If there is no remote version yet, our version is always newer by definition
      remote_version = latest_synced_version(content_id)
      return false if remote_version.nil?

      remote_version.to_i >= payload_version.to_i
    end

    # Gets the latest synced version for a document from Redis
    def latest_synced_version(content_id)
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

  private

    def redlock_client
      @redlock_client ||= Redlock::Client.new(
        Rails.configuration.redlock_redis_instances,
        retry_count: RETRY_COUNT,
        retry_delay: RETRY_DELAY,
        retry_jitter: RETRY_JITTER,
      )
    end
  end
end
