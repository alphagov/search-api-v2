class PublishingApiDocument
  # When a document is unpublished in the source system, its document type changes to one of
  # these values. While semantically different for other systems, we only need to know that they
  # imply removal from search.
  UNPUBLISH_DOCUMENT_TYPES = %w[gone redirect substitute vanish].freeze

  # Currently, we only allow documents in English to be added to search because that is the
  # behaviour of the existing search. This may change in the future.
  PERMITTED_LOCALES = %w[en].freeze

  def initialize(document_hash)
    @document_hash = document_hash

    @document_type = document_hash[:document_type]
    @base_path = document_hash[:base_path]
    @external_link = document_hash.dig(:details, :url)
    @locale = document_hash[:locale]
  end

  def action
    if unpublish?
      PublishingApiAction::Unpublish.new(document_hash)
    elsif ignore?
      PublishingApiAction::Ignore.new(document_hash)
    else
      PublishingApiAction::Publish.new(document_hash)
    end
  end

  delegate :synchronize, to: :action

private

  attr_reader :document_hash, :document_type, :base_path, :external_link, :locale

  def unpublish?
    UNPUBLISH_DOCUMENT_TYPES.include?(document_type)
  end

  def ignore?
    on_ignorelist? || ignored_locale? || unaddressable?
  end

  def on_ignorelist?
    return false if ignorelist_excepted_path?

    Rails.configuration.document_type_ignorelist.any? { document_type.match?(_1) }
  end

  def ignorelist_excepted_path?
    return false if base_path.blank?

    Rails.configuration.document_type_ignorelist_path_overrides.any? { _1.match?(base_path) }
  end

  def ignored_locale?
    locale.present? && !PERMITTED_LOCALES.include?(locale)
  end

  def unaddressable?
    base_path.blank? && external_link.blank?
  end
end
