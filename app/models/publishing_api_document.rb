class PublishingApiDocument
  # When a document is unpublished in the source system, its document type changes to one of
  # these values. While semantically different for other systems, we only need to know that they
  # imply removal from search.
  UNPUBLISH_DOCUMENT_TYPES = %w[gone redirect substitute vanish].freeze

  # Currently, we only allow documents in English to be added to search because that is the
  # behaviour of the existing search. This may change in the future.
  PERMITTED_LOCALES = %w[en].freeze

  include ::PublishingApi::Metadata
  include ::PublishingApi::Content

  attr_reader :content_id, :payload_version

  def initialize(
    document_hash,
    put_service: DiscoveryEngine::Put.new,
    delete_service: DiscoveryEngine::Delete.new
  )
    @document_hash = document_hash

    @document_type = document_hash.fetch(:document_type)
    @content_id = document_hash.fetch(:content_id)
    @base_path = document_hash[:base_path]
    @external_link = document_hash.dig(:details, :url)
    @locale = document_hash[:locale]
    @payload_version = document_hash[:payload_version]&.to_i

    @put_service = put_service
    @delete_service = delete_service
  end

  def synchronize
    if unpublish?
      delete_service.call(content_id, payload_version:)
    elsif ignore?
      Rails.logger.info("Ignoring document '#{content_id}'")
    else
      put_service.call(content_id, metadata, content:, payload_version:)
    end
  end

private

  attr_reader :document_hash, :document_type, :base_path, :external_link, :locale,
              :put_service, :delete_service

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
