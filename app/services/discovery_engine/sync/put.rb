module DiscoveryEngine::Sync
  class Put
    # The MIME type of the content to be indexed
    MIME_TYPE = "text/html".freeze
    # The range of the backoff waiting period when retrying requests due to resource exhaustion
    RESOURCE_EXHAUSTION_BACKOFF_RANGE = 1.5..6.0

    include DocumentName
    include Logging

    def initialize(client: ::Google::Cloud::DiscoveryEngine.document_service(version: :v1))
      @client = client
    end

    def call(content_id, metadata, content: "", payload_version: nil)
      client.update_document(
        document: {
          id: content_id,
          name: document_name(content_id),
          json_data: metadata.merge(payload_version:).to_json,
          content: {
            mime_type: MIME_TYPE,
            # The Google client expects an IO object to extract raw byte content from
            raw_bytes: StringIO.new(content),
          },
        },
        allow_missing: true,
      )

      log(Logger::Severity::INFO, "Successfully added/updated", content_id:, payload_version:)
      Metrics.increment_counter(:discovery_engine_requests, type: "put", status: "success")
    rescue Google::Cloud::ResourceExhaustedError
      # TODO: This is a very nasty hack, but there is no quick fix for this problem on the
      # Publishing API side.
      #
      # Our upstream content source (Publishing API) often unnecessarily publishes several (up to 5
      # or more) messages for the same document in rapid succession due to internal implementation
      # details (possibly relating to "link expansion"). This causes us in turn to send several
      # quick fire requests to the Discovery Engine API to update said document, leading to this
      # resource exhaustion error as the Discovery Engine API has an internal limit on document
      # updates of *roughly* once per second.
      #
      # To work around this, when we get this error, we wait for a random amount of time in the
      # RESOURCE_EXHAUSTION_BACKOFF_RANGE range and then retry the request after checking that a
      # newer update hasn't already been made (as determined by `payload_version`). Unfortunately
      # there is no way to perform atomic/transactional/locking operations on the Discovery Engine
      # so this is very much best effort and will be competing with other processes for the same
      # document – but it should at least slightly reduce the number of errors we see.
      wait_period = rand(RESOURCE_EXHAUSTION_BACKOFF_RANGE)
      log(
        Logger::Severity::WARN,
        "Resource exhausted trying to update document, waiting #{wait_period} seconds",
        content_id:, payload_version:,
      )
      sleep(wait_period)

      remote_payload_version = client
                                 .get_document(name: document_name(content_id))
                                 &.struct_data
                                 &.fetch("payload_version")
      if remote_payload_version && remote_payload_version > payload_version
        log(
          Logger::Severity::INFO,
          "Remote document is newer (payload_version: #{remote_payload_version}), skipping",
          content_id:, payload_version:,
        )
        return
      end

      retry
    rescue Google::Cloud::Error => e
      log(
        Logger::Severity::ERROR,
        "Failed to add/update document due to an error (#{e.message})",
        content_id:, payload_version:,
      )
      GovukError.notify(e)
      Metrics.increment_counter(:discovery_engine_requests, type: "put", status: "error")
    end

  private

    attr_reader :client
  end
end
