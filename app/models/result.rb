# Represents an individual result as expected by Finder Frontend
class Result
  MAX_DESCRIPTION_WORDS = 40

  include ActiveModel::Model

  attr_accessor :_id, :content_id, :title, :description_with_highlighting, :link, :public_timestamp,
                :government_name, :parts, :part_of_taxonomy_tree, :format, :is_historic,
                :content_purpose_supergroup, :content_store_document_type

  # Creates a new instance based on a document stored in Discovery Engine, transforming fields as
  # appropriate to match what is expected by Finder Frontend
  def self.from_stored_document(document)
    attrs = document.symbolize_keys

    public_timestamp = Time.zone.at(attrs[:public_timestamp]).iso8601 if attrs[:public_timestamp]
    description = attrs[:description]&.truncate_words(MAX_DESCRIPTION_WORDS)

    new(
      attrs
        # Fields Discovery Engine documents contains verbatim
        .slice(
          :content_id, :title, :link, :content_purpose_supergroup, :parts, :part_of_taxonomy_tree,
          :government_name
        )
        # Fields that need to be transformed
        .merge(
          # Legacy Elasticsearch implementation detail for backwards compatibility
          # (equal to link for internal content, content_id for external content)
          _id: attrs[:link]&.start_with?("/") ? attrs[:link] : attrs[:content_id],
          # We're not currently using snippeting, and there is no way to get Discovery Engine to
          # highlight a description, but consumers expect this field to be present
          description_with_highlighting: description,
          # No longer relevant and equal to document type now, but here for backwards compatibility
          format: attrs[:document_type],
          # Stored as a timestamp in Discovery Engine, but we want to return an ISO8601 string
          public_timestamp:,
          # Different name in Discovery Engine documents
          content_store_document_type: attrs[:document_type],
          # Stored as an integer in Discovery Engine to allow boosting, but consumers expect boolean
          is_historic: attrs[:is_historic] == 1,
        ),
    )
  end
end
