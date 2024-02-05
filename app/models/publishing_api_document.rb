class PublishingApiDocument
  include ::PublishingApi::Action
  include ::PublishingApi::Metadata
  include ::PublishingApi::Content

  attr_reader :content_id, :payload_version

  def initialize(
    document_hash,
    put_service: DiscoveryEngine::Sync::Put.new,
    delete_service: DiscoveryEngine::Sync::Delete.new
  )
    @document_hash = document_hash
    @put_service = put_service
    @delete_service = delete_service

    @content_id = document_hash.fetch(:content_id)
    @payload_version = document_hash[:payload_version]&.to_i
  end

  def synchronize
    if skip?
      Metrics::Exported.increment_counter(:documents_skipped)
      log("skip (#{action_reason})")
    elsif sync?
      log("sync")
      Metrics::Exported.increment_counter(:documents_synced)
      put_service.call(content_id, metadata, content:, payload_version:)
    elsif desync?
      log("desync (#{action_reason}))")
      Metrics::Exported.increment_counter(:documents_desynced)
      delete_service.call(content_id, payload_version:)
    else
      raise "Cannot determine action for document: #{content_id}"
    end
  end

private

  attr_reader :document_hash, :put_service, :delete_service

  def log(message)
    combined_message = sprintf(
      "[%s] Processing document to %s with content_id:%s update_type:%s link:%s payload_version:%d",
      self.class.name,
      message,
      content_id,
      update_type,
      link,
      payload_version,
    )
    Rails.logger.info(combined_message)
  end
end
