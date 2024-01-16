module PublishingApi
  module Metadata
    WEBSITE_ROOT = "https://www.gov.uk".freeze

    # Some manuals are special in that the documents contained within do not include the path of
    # their parent manual in their `details` field. Instead, the path of the parent manual is
    # implicit in the path of the document itself. Any document whose path starts with one of the
    # paths in this list will have its `manual` field set accordingly.
    IMPLICIT_MANUAL_PATHS = %w[/service-manual].freeze

    # Extracts a hash of structured metadata about this document.
    def metadata
      {
        content_id: document_hash[:content_id],
        title: document_hash[:title],
        description: document_hash[:description],
        link:,
        url:,
        public_timestamp:,
        document_type: document_hash[:document_type],
        content_purpose_supergroup: document_hash[:content_purpose_supergroup],
        part_of_taxonomy_tree: document_hash.dig(:links, :taxons) || [],
        # Vertex can only currently boost on numeric fields, not booleans
        is_historic: historic? ? 1 : 0,
        government_name:,
        organisation_state:,
        locale: document_hash[:locale],
        world_locations:,
        organisations:,
        topical_events:,
        manual:,
        parts:,
        debug:,
      }.compact_blank
    end

    def link
      document_hash[:base_path].presence || document_hash.dig(:details, :url)
    end

  private

    def link_relative?
      link&.start_with?("/")
    end

    def url
      return link unless link_relative?

      WEBSITE_ROOT + link
    end

    def public_timestamp
      return nil unless document_hash[:public_updated_at]

      # rubocop:disable Rails/TimeZone (string already contains timezone info which would be lost)
      Time.parse(document_hash[:public_updated_at]).to_i
      # rubocop:enable Rails/TimeZone
    end

    def historic?
      political = document_hash.dig(:details, :political) || false
      government = document_hash.dig(:expanded_links, :government)&.first

      political && government&.dig(:details, :current) == false
    end

    def government_name
      document_hash
        .dig(:expanded_links, :government)
        &.first
        &.dig(:title)
    end

    def organisation_state
      document_hash
        .dig(:details, :organisation_govuk_status, :status)
    end

    def world_locations
      # This isn't great, but there is no slug coming through from publishing-api and the v1
      # search-api also manually generates slugs for world locations by parameterizing the title.
      document_hash
        .dig(:expanded_links, :world_locations)
        &.map { _1[:title].parameterize }
    end

    def organisations
      # This isn't great, but it replicates the behaviour of the v1 search-api which also takes the
      # last part of the slug and adds in an organisation value if the document itself represents an
      # organisation.
      organisation_links = document_hash.dig(:expanded_links, :organisations) || []

      organisation_links
        .map { _1[:base_path].split("/").last }
        .tap do |links|
          if document_hash[:document_type] == "organisation"
            links << document_hash[:base_path].split("/").last
          end
        end
    end

    def topical_events
      # This isn't great, but there is no slug coming through from publishing-api and the v1
      # search-api also manually generates slugs for topical events by taking the last part of the
      # base_path.
      document_hash
        .dig(:expanded_links, :topical_events)
        &.map { _1[:base_path].split("/").last }
    end

    def manual
      document_hash.dig(:details, :manual, :base_path) ||
        IMPLICIT_MANUAL_PATHS.find { document_hash[:base_path]&.start_with?(_1) }
    end

    def parts
      parts_from_parts || parts_from_attachments
    end

    def parts_from_parts
      document_hash
        .dig(:details, :parts)
        &.map do
          {
            slug: _1[:slug],
            title: _1[:title],
            body: BodyContent.new(_1[:body]).summarized_text_content,
          }
        end
    end

    def parts_from_attachments
      document_hash
        .dig(:details, :attachments)
        &.map {
          # Skip any attachments that aren't directly nested underneath this document
          #
          # This is replicated from v1 search-api behaviour, and is a workaround for the fact that
          # the consumers always expect a slug rather than a URL, so parts cannot have a URL that
          # doesn't match the document's base path.
          next unless _1[:url].start_with?(document_hash[:base_path])

          # The slug for a part from an attachment is the part of the URL that comes after the
          # parent document's base path.
          slug = _1[:url].sub(document_hash[:base_path], "").sub(%r{^/}, "").sub(%r{/$}, "")
          {
            slug:,
            title: _1[:title],
            # TODO: We don't receive any body content for attachments as part of the message from
            # publishing-api. This needs to be fetched from publishing-api separately.
            body: "",
          }
        }&.compact_blank
    end

    # Useful information about the document that is not intended to be exposed to the end user.
    def debug
      {
        last_synced_at: Time.zone.now.iso8601,
        payload_version: document_hash[:payload_version]&.to_i,
      }
    end
  end
end
