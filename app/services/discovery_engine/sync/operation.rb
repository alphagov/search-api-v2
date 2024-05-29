module DiscoveryEngine::Sync
  class Operation
    def initialize(content_id, payload_version: nil, client: nil)
      @content_id = content_id
      @payload_version = payload_version
      @client = client || ::Google::Cloud::DiscoveryEngine.document_service(version: :v1)
    end

  private

    attr_reader :content_id, :payload_version, :client
  end
end
