module PublishingApi
  module Action
    # When a document is unpublished in the source system, its document type changes to one of
    # these values. While semantically different for other systems, we only need to know that they
    # imply removal from search.
    UNPUBLISH_DOCUMENT_TYPES = %w[gone redirect substitute vanish].freeze

    # Currently, we only allow documents in English to be added to search because that is the
    # behaviour of the existing search. This may change in the future.
    PERMITTED_LOCALES = %w[en].freeze

    def sync?
      return false if skip?

      !desync?
    end

    def desync?
      return false if skip?

      unpublish_type? || on_ignorelist? || unaddressable? || withdrawn?
    end

    def skip?
      # Do not proactively desync documents with an ignored locale, as they may have content with a
      # non-ignored locale with the same content_id.
      ignored_locale?
    end

    def action_reason
      if ignored_locale?
        "locale not permitted (#{locale})"
      elsif unpublish_type?
        "unpublish type (#{document_type})"
      elsif on_ignorelist?
        "document_type on ignorelist (#{document_type})"
      elsif unaddressable?
        "unaddressable"
      elsif withdrawn?
        "withdrawn"
      end
    end

  private

    def unpublish_type?
      UNPUBLISH_DOCUMENT_TYPES.include?(document_type)
    end

    # rubocop:disable Style/CaseEquality (no semantically equal alternative to compare String/Regex)
    def on_ignorelist?
      return false if ignorelist_excepted_path?

      Rails.configuration.document_type_ignorelist.any? { _1 === document_type }
    end

    def ignorelist_excepted_path?
      return false if base_path.blank?

      Rails.configuration.document_type_ignorelist_path_overrides.any? { _1 === base_path }
    end
    # rubocop:enable Style/CaseEquality

    def ignored_locale?
      locale.present? && !PERMITTED_LOCALES.include?(locale)
    end

    def unaddressable?
      base_path.blank? && external_link.blank?
    end

    def withdrawn?
      document_hash[:withdrawn_notice].present?
    end

    def update_type
      document_hash[:update_type]
    end

    def document_type
      document_hash.fetch(:document_type)
    end

    def base_path
      document_hash[:base_path]
    end

    def external_link
      document_hash.dig(:details, :url)
    end

    def locale
      document_hash[:locale]
    end
  end
end
