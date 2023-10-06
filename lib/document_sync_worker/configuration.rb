module DocumentSyncWorker
  class Configuration
    attr_accessor :logger, :message_queue_name, :repository

    def initialize
      @logger = ActiveSupport::Logger.new($stdout, progname: "DocumentSyncWorker")
      @logger.formatter = proc do |level, datetime, progname, message|
        hash = {
          message:,
          level:,
          progname:,
          "@timestamp": datetime.utc.iso8601(3),
          tags: %w[document_sync_worker],
        }

        "#{hash.to_json}\n"
      end
    end
  end
end
