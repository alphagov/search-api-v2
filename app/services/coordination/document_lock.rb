module Coordination
  # Handles locking documents using Redlock to avoid multiple workers attempting to operate on the
  # same document simultaneously.
  #
  # If lock acquisition fails (for example, if Redis is down or the configured number of attempts
  # have been exhausted), the error is logged but not propagated. This allows consumers to continue
  # their operation even if locking is unavailable, enabling "graceful" degradation at the cost of
  # potential rare race conditions (which should not have major impact because when we receive a
  # number of messages for a document in quick succession, they usually contain the same content
  # anyway).
  class DocumentLock
    # Redis key prefix for locks and versions
    KEY_PREFIX = "search_api_v2:sync_lock".freeze

    # Time-to-live for document locks if not explicitly released
    TTL = 30.seconds

    # Options for Redlock client around handling retries
    RETRY_COUNT = 5
    RETRY_DELAY = 5.seconds
    RETRY_JITTER = 5.seconds

    def initialize(content_id)
      @content_id = content_id
    end

    # Attempts to lock the document until unlocked or the lock expires, returns whether or not the
    # lock was successfully acquired, and logs any error if not.
    def acquire
      @lock_info = redlock_client.lock(key, TTL.in_milliseconds)
      log_acquire_failure unless @lock_info

      !!@lock_info
    rescue StandardError => e
      log_acquire_failure(e)

      false
    end

    # Releases the lock on the document if it is currently locked by this instance.
    def release
      return false unless @lock_info

      redlock_client.unlock(@lock_info)
      @lock_info = nil
    end

  private

    attr_reader :content_id

    def key
      "#{KEY_PREFIX}:#{content_id}"
    end

    def redlock_client
      @redlock_client ||= Redlock::Client.new(
        Rails.configuration.redlock_redis_instances,
        retry_count: RETRY_COUNT,
        retry_delay: RETRY_DELAY.in_milliseconds,
        retry_jitter: RETRY_JITTER.in_milliseconds,
      )
    end

    def log_acquire_failure(error = nil)
      Rails.logger.warn(
        "[#{self.class.name}] Failed to acquire lock for document: #{content_id}",
      )
      GovukError.notify(error) if error
    end
  end
end
