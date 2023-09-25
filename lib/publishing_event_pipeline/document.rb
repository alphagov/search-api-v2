module PublishingEventPipeline
  # Domain model for a representation of a single piece of content on GOV.UK that can be stored in,
  # and retrieved from, a search engine
  #
  # @attr_reader [String] content_id The unique identifier for the document in the publishing system
  # @attr_reader [Hash{String, Symbol => Object}] metadata Arbitrary metadata about the document
  # @attr_reader [String, nil] unstructured_content The unstructured textual content of the
  #   document, if any
  Document = Data.define(:content_id, :metadata, :unstructured_content) do
    def self.from_message_hash(message_hash)
      metadata = {
        base_path: message_hash.fetch("base_path"),
      }
      new(message_hash.fetch("content_id"), metadata, nil)
    end
  end
end
