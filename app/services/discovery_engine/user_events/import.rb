module DiscoveryEngine::UserEvents
  # Handles importing user events from an analytics dataset in BigQuery into Discovery Engine.
  #
  # This allows Discovery Engine to "learn" from user behaviour (for example. search results clicked
  # or pages viewed) to deliver better results for users.
  #
  # There are several different event types, each of which have two tables in the BigQuery dataset:
  # one for historical data (up until the previous day), and one for "intraday" data (live data from
  # today but not 100% reliable). To ensure the model gets both the latest _and_ the most reliable
  # data, we need to import from both tables (note that event imports are idempotent, so it's okay
  # if the same event gets imported several times). This is done by invoking this service from a
  # scheduled Rake task.
  #
  # Each instance of this class is scoped to an event type and date. If the given date is today, the
  # data will be fetched from the event type's intraday table, otherwise the main table is used.
  #
  # The import process is asynchronous on Discovery Engine, but only takes a couple of minutes for
  # an average day's worth of events. For simplicity, rather than configuring a Cloud Storage bucket
  # for error logs, we just block until the import has completed and raise an exception if it
  # failed. Any failures can be viewed in the Google Cloud Console UI.
  #
  # see https://cloud.google.com/generative-ai-app-builder/docs/import-user-events
  class Import
    # The name of the BigQuery dataset where the analytics events are stored (created through data
    # pipelines defined in `govuk-infrastructure`)
    BIGQUERY_DATASET = "analytics_events_vertex".freeze

    # The event types we can import from the BigQuery dataset
    EVENT_TYPES = %w[search view-item view-item-external-link].freeze

    def self.import_all(date)
      EVENT_TYPES.each do |event_type|
        new(event_type, date:).call
      end
    end

    def initialize(
      event_type,
      date:,
      client: ::Google::Cloud::DiscoveryEngine.user_event_service(version: :v1)
    )
      @event_type = event_type
      @date = date
      @client = client
    end

    def call
      logger.info("Triggering import_user_events operation")
      operation = client.import_user_events(
        bigquery_source: {
          project_id: Rails.configuration.google_cloud_project_id,
          dataset_id: BIGQUERY_DATASET,
          table_id:,
          partition_date:,
        },
        parent: Rails.configuration.discovery_engine_datastore,
      )

      logger.info("Waiting for import_user_events operation to finish remotely")
      operation.wait_until_done! do |response|
        results = response.results
        raise results.message if response.error?

        count = results.joined_events_count + results.unjoined_events_count

        logger.info("Successfully imported #{count} user events")
      end
    end

  private

    attr_reader :event_type, :date, :client

    def table_id
      if date.today?
        "#{event_type}-intraday-event"
      else
        "#{event_type}-event"
      end
    end

    def partition_date
      Google::Type::Date.new(year: date.year, month: date.month, day: date.day)
    end

    def logger
      @logger ||= ActiveSupport::TaggedLogging
        .new(Rails.logger)
        .tagged(self.class.name, "event_type=#{event_type}", "date=#{date}")
    end
  end
end
