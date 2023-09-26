module PublishingEventPipeline
  class MetadataExtractor
    def call(message_hash)
      {
        base_path: message_hash.fetch("base_path"),
      }
    end
  end
end
