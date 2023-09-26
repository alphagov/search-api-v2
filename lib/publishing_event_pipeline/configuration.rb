module PublishingEventPipeline
  class Configuration
    attr_accessor :logger, :message_queue_name, :repository

    def initialize
      @logger = Logger.new($stdout, progname: "PublishingEventPipeline")
    end
  end
end
