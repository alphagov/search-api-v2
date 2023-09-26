module PublishingEventPipeline
  class Configuration
    attr_accessor :logger, :repository

    def initialize
      @logger = Logger.new($stdout)
    end
  end
end
