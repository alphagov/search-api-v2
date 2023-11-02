module PublishingApiDocument
  class Ignore < Base
    # Synchonisation is a no-op for ignored documents
    def synchronize(*)
      Rails.logger.info("Ignoring document #{content_id} for synchronisation")
    end
  end
end
