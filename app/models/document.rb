# Domain model for a single piece of content on GOV.UK that can be stored in, and retrieved from, a
# search engine
#
# @attr_reader [String] content_id A unique UUID for this document across all GOV.UK content
# @attr_reader [String, nil] title The title of the document
Document = Data.define(:content_id, :title) do
  # Creates a document from a message hash from the "published documents" message queue.
  #
  # @param message_hash [Hash] The message hash to create the document from.
  # @return [Document] The newly created Document instance.
  def self.from_message_hash(message_hash)
    new(
      content_id: message_hash.fetch("content_id"),
      title: message_hash["title"],
    )
  end
end
