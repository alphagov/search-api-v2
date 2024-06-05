module DiscoveryEngine::Sync
  class Operation
    include Versioning

    def initialize(content_id, payload_version: nil, client: nil)
      @content_id = content_id
      @payload_version = payload_version
      @client = client || ::Google::Cloud::DiscoveryEngine.document_service(version: :v1)
    end

  private

    attr_reader :content_id, :payload_version, :client

    def lock
      @lock ||= Coordination::DocumentLock.new(content_id)
    end

    def document_name
      "#{Rails.configuration.discovery_engine_datastore_branch}/documents/#{content_id}"
    end

    def log(level, message)
      combined_message = sprintf(
        "[%s] %s content_id:%s payload_version:%d",
        self.class.name,
        message,
        content_id,
        payload_version,
      )
      Rails.logger.add(level, combined_message)
    end
  end
end
