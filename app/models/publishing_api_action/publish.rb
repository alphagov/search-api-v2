module PublishingApiAction
  class Publish < Base
    include ::PublishingApi::Metadata
    include ::PublishingApi::Content

    # Synchronize the document to the given service (i.e. create or update it remotely)
    def synchronize(service: DiscoveryEngine::Put.new)
      service.call(content_id, metadata, content:, payload_version:)
    end
  end
end
