module DiscoveryEngine
  class Delete
    include DocumentName

    def initialize(client: ::Google::Cloud::DiscoveryEngine.document_service(version: :v1))
      @client = client
    end

    def call(content_id, payload_version: nil)
      client.delete_document(name: document_name(content_id))

      Rails.logger.info(sprintf("[GCDE][DELETE %s@v%s]", content_id, payload_version))
    rescue Google::Cloud::NotFoundError => e
      # TODO: Should we eventually send this to Sentry? A document not existing is a relatively
      # common error initially as an unpublish request may come through before we've imported the
      # document to begin with.
      Rails.logger.warn(sprintf("[GCDE][DELETE %s@v%s] %s", content_id, payload_version, e.message))
    rescue Google::Cloud::Error => e
      Rails.logger.error(
        sprintf("[GCDE][DELETE %s@v%s] %s", content_id, payload_version, e.message),
      )
      GovukError.notify(e)
    end

  private

    attr_reader :client
  end
end
