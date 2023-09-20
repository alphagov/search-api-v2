require "domain/searchable_document_data"

module PublishEventPipeline
  # Domain model for a content change event coming through from a publishing system
  #
  # @attr_reader [String] update_type The type of update that has occurred
  # @attr_reader [Integer] payload_version The payload version of the update
  # @attr_reader [Document] document The document that has been added/modified/deleted
  PublishEvent = Data.define(:update_type, :payload_version, :document) do
    # Creates a PublishEvent from a message hash conforming to the publishing schema.
    #
    # @param message_hash [Hash] The message hash to create the document from.
    # @return [PublishEvent] The newly created PublishEvent instance.
    def self.from_message_hash(message_hash)
      new(
        update_type: message_hash.fetch("update_type"),
        payload_version: message_hash.fetch("payload_version"),
        document: SearchableDocumentData.new(
          content_id: message_hash.fetch("content_id"),
          title: message_hash["title"],
        ),
      )
    end
  end
end
