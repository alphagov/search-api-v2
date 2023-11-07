module DiscoveryEngine
  class Delete
    include DocumentName
    include Logging

    def initialize(client: ::Google::Cloud::DiscoveryEngine.document_service(version: :v1))
      @client = client
    end

    def call(content_id, payload_version: nil)
      client.delete_document(name: document_name(content_id))

      log(Logger::Severity::INFO, "Successfully deleted", content_id:, payload_version:)
    rescue Google::Cloud::NotFoundError => e
      # TODO: Should we eventually send this to Sentry? A document not existing is a relatively
      # common error initially as an unpublish request may come through before we've imported the
      # document to begin with.
      log(
        Logger::Severity::WARN,
        "Failed to delete document as it doesn't exist remotely (#{e.message})",
        content_id:, payload_version:,
      )
    rescue Google::Cloud::Error => e
      log(
        Logger::Severity::ERROR,
        "Failed to delete document due to an error (#{e.message})",
        content_id:, payload_version:,
      )
      GovukError.notify(e)
    end

  private

    attr_reader :client
  end
end
