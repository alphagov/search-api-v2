module DocumentSyncWorker
  class Configuration
    attr_accessor :logger, :message_queue_name, :repository

    def initialize
      @logger = Logger.new($stdout, progname: "DocumentSyncWorker")
    end
  end
end
