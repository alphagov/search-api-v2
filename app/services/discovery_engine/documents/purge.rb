module DiscoveryEngine::Documents
  class Purge
    def call
      logger.info("Triggering purge_documents operation")
      operation = DiscoveryEngine::Clients.document_service.purge_documents(
        parent: Branch.default.name,
        filter: "*",
        force: true,
      )

      logger.info("Waiting for purge_documents operation to finish remotely")
      operation.wait_until_done! do |response|
        results = response.results
        raise results.message if response.error?

        logger.info("Successfully purged #{results.purge_count} documents")
      end
    end

  private

    def logger
      @logger ||= ActiveSupport::TaggedLogging
        .new(Rails.logger)
        .tagged(self.class.name)
    end
  end
end
