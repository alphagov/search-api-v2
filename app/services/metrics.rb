module Metrics
  CLIENT = PrometheusExporter::Client.default
  COUNTERS = {
    ### User facing counters
    search_requests: CLIENT.register(
      :counter, "search_api_v2_search_requests", "number of incoming search requests"
    ),
    ### Synchronisation counters
    incoming_messages: CLIENT.register(
      :counter, "search_api_v2_incoming_messages", "number of incoming messages from Publishing API"
    ),
    message_processing_errors: CLIENT.register(
      :counter,
      "search_api_v2_message_processing_errors",
      "number of messages from Publishing API that failed to process",
    ),
    discovery_engine_requests: CLIENT.register(
      :counter,
      "search_api_v2_discovery_engine_requests",
      "number of requests to Discovery Engine",
    ),
    documents_synced: CLIENT.register(
      :counter, "search_api_v2_documents_synced", "number of documents synced to Discovery Engine"
    ),
    documents_desynced: CLIENT.register(
      :counter,
      "search_api_v2_documents_desynced",
      "number of documents desynced from Discovery Engine",
    ),
    documents_skipped: CLIENT.register(
      :counter,
      "search_api_v2_documents_skipped",
      "number of documents skipped from syncing to Discovery Engine",
    ),
  }.freeze

  def self.increment_counter(counter, labels = {})
    Rails.logger.warn("Unknown counter: #{counter}") and return unless COUNTERS.key?(counter)

    COUNTERS[counter].observe(1, labels)
  rescue StandardError
    # Metrics are best effort only, don't raise if they fail
  end
end
