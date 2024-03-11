module DiscoveryEngine::Sync
  module Locking
    class FailedToAcquireLockError < StandardError; end
    class DocumentOlderThanRemoteError < StandardError; end

    # Redis key prefix for locks
    LOCK_KEY_PREFIX = "search_api_v2:sync_lock".freeze

    # Time-to-live for document locks if not explicitly released
    DOCUMENT_LOCK_TTL = 30.seconds.in_milliseconds

    # Options for Redlock client around handling retries
    RETRY_COUNT = 10 # TODO: can probably be lower
    RETRY_DELAY = 5.seconds.in_milliseconds
    RETRY_JITTER = 5.seconds.in_milliseconds

    # Locks a document while a critical section block is executed to avoid multiple workers
    # competing to update the same document.
    def with_locked_document(document_id, payload_version:, &critical_section)
      redlock_client.lock!(
        "#{LOCK_KEY_PREFIX}:#{document_id}",
        DOCUMENT_LOCK_TTL,
      ) do
        Rails.logger.add(
          Logger::Severity::INFO,
          "[#{self.class.name}] Lock acquired for document: #{document_id}, " \
            "payload_version: #{payload_version}",
        )
        # TODO: Check for latest version, raise DocumentOlderThanRemoteError and release lock if newer

        critical_section.call

        # TODO: Set latest version
        Rails.logger.add(
          Logger::Severity::INFO,
          "[#{self.class.name}] Releasing lock for document: #{document_id}, " \
            "payload_version: #{payload_version}",
        )
      end
    rescue Redlock::LockError
      # TODO: One of our discussed fallback options is to run the critical section anyway in case
      # lock acquisition fails.
      raise FailedToAcquireLockError, "Failed to acquire lock for document: #{document_id}"
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
