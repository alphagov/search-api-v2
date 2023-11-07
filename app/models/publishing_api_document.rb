class PublishingApiDocument
  include ::PublishingApi::Action
  include ::PublishingApi::Metadata
  include ::PublishingApi::Content

  attr_reader :content_id, :payload_version

  def initialize(
    document_hash,
    put_service: DiscoveryEngine::Put.new,
    delete_service: DiscoveryEngine::Delete.new
  )
    @document_hash = document_hash
    @put_service = put_service
    @delete_service = delete_service

    @content_id = document_hash.fetch(:content_id)
    @payload_version = document_hash[:payload_version]&.to_i
  end

  def synchronize
    if publish?
      put_service.call(content_id, metadata, content:, payload_version:)
    elsif unpublish?
      delete_service.call(content_id, payload_version:)
    else
      Rails.logger.info("Ignoring document '#{content_id}': #{ignore_reason}")
    end
  end

private

  attr_reader :document_hash, :put_service, :delete_service
end
