module DiscoveryEngine::Sync
  class Operation
    def initialize(content_id, payload_version: nil)
      @content_id = content_id
      @payload_version = payload_version
    end

  private

    attr_reader :content_id, :payload_version
  end
end
