module DocumentSyncWorker
  class Configuration
    attr_accessor :logger, :message_queue_name, :repository

    def initialize
      @logger = Rails.logger
    end
  end
end
