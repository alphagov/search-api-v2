module DiscoveryEngine::UserEvents
  # Handles purging user events that occurred between two dates from Discovery Engine.
  #
  # The main use for this is as part of a scheduled task to clean up user data that is about to fall
  # outside our agreed retention period.
  #
  # The purge process is asynchronous on Discovery Engine and may take some time, but as this should
  # only ever be called as part of a background task, we can just block until the remote operation
  # has completed and raise an error if it failed.
  class Purge
    # How long to keep user events for (defined by our privacy policy/DPIA)
    DEFAULT_RETENTION_PERIOD = 2.years
    # The maximum date range we can purge events for (Discovery Engine does not support purging more
    # than 30 days worth of events at a time)
    MAX_DAYS = 30
    # The date format for the event filter (we always purge from midnight UTC for consistency)
    DATE_FORMAT = "%Y-%m-%dT00:00:00Z".freeze

    # Purge one week's worth of events before the last day of the retention period
    def self.purge_final_week_of_retention_period
      final_day_of_retention_period = DEFAULT_RETENTION_PERIOD.ago.to_date

      new(
        from: final_day_of_retention_period,
        to: final_day_of_retention_period + 1.week,
      ).call
    end

    def initialize(from:, to:)
      @from = from.to_date
      @to = to.to_date.tomorrow # end of this day == 0:00am on the next day
      raise ArgumentError, "from date is after to date" if @from >= @to
      raise ArgumentError, "date range is too long" if (@to - @from) > MAX_DAYS
    end

    def call
      logger.info("Triggering purge_user_events operation")
      operation = DiscoveryEngine::Clients.user_event_service.purge_user_events(
        filter:,
        parent: DataStore.default.name,
        force: true,
      )

      logger.info("Waiting for purge_user_events operation to finish remotely")
      operation.wait_until_done! do |response|
        results = response.results
        raise results.message if response.error?

        logger.info("Successfully purged #{results.purge_count} user events")
      end
    end

  private

    attr_reader :from, :to

    def filter
      sprintf(
        'eventTime > "%s" eventTime < "%s"',
        from.strftime(DATE_FORMAT),
        to.strftime(DATE_FORMAT),
      )
    end

    def logger
      @logger ||= ActiveSupport::TaggedLogging
        .new(Rails.logger)
        .tagged(self.class.name, "from=#{from},to=#{to}")
    end
  end
end
