module Metrics
  module Exported
    CLIENT = PrometheusExporter::Client.default
    COUNTERS = {
      ### Synchronisation counters
      documents_processed_total: CLIENT.register(
        :counter,
        "search_api_v2_documents_processed_total",
        "documents synchronised to Discovery Engine",
        labels: %i[action],
      ),
    }.freeze
    HISTOGRAMS = {
      ### Syncing histograms
      total_processing_duration: CLIENT.register(
        :histogram,
        "search_api_v2_total_processing_duration",
        "total time taken to process an incoming message from Publishing API (seconds)",
        buckets: [0.1, 0.5, 1, 2, 5],
      ),
      ### VAIS response duration histograms
      vertex_search_request_duration: CLIENT.register(
        :histogram,
        "search_api_v2_vertex_search_request_duration",
        "total time taken for google vertex to respond to a search request (seconds)",
        buckets: [0.1, 0.5, 1, 2, 5],
      ),
    }.freeze

    def self.increment_counter(counter, labels = {})
      Rails.logger.warn("Unknown counter: #{counter}") and return unless COUNTERS.key?(counter)

      COUNTERS[counter].observe(1, labels)
    rescue StandardError
      # Metrics are best effort only, don't raise if they fail
    end

    def self.observe_duration(histogram, labels = {}, &block)
      unless HISTOGRAMS.key?(histogram)
        Rails.logger.warn("Unknown histogram: #{histogram}")
        return block.call
      end

      result = nil
      duration = Benchmark.realtime do
        result = block.call
      end

      begin
        HISTOGRAMS[histogram].observe(duration, labels)
      rescue StandardError
        # Metrics are best effort only, don't raise if they fail
      end

      result
    end
  end
end
