module PublishingApiDocument
  class Unpublish < Base
    # Synchronize the document to the given service (i.e. delete it remotely).
    def synchronize(service: DiscoveryEngine::Delete.new)
      service.call(content_id, payload_version:)
    end
  end
end
