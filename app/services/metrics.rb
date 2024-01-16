module Metrics
  CLIENT = PrometheusExporter::Client.default
  COUNTERS = {
    search_requests: CLIENT.register(
      :counter, "search_api_v2_search_requests", "number of incoming search requests"
    ),
    put_requests: CLIENT.register(
      :counter, "search_api_v2_put_requests", "number of put requests to Discovery Engine"
    ),
    delete_requests: CLIENT.register(
      :counter, "search_api_v2_delete_requests", "number of delete requests to Discovery Engine"
    ),
  }.freeze

  def self.increment_counter(counter, labels = {})
    Rails.logger.warn("Unknown counter: #{counter}") and return unless COUNTERS.key?(counter)

    COUNTERS[counter].observe(1, labels)
  rescue StandardError
    # Metrics are best effort only, don't raise if they fail
  end
end
