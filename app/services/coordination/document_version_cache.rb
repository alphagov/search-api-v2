module Coordination
  # Keeps track of the latest version of a document that has been synced. This allows us to avoid
  # race conditions where an older document version is processed after a newer one.
  class DocumentVersionCache
    # Redis key prefix for versions
    VERSION_KEY_PREFIX = "search_api_v2:latest_synced_version".freeze

    def initialize(content_id, payload_version:)
      @content_id = content_id
      @payload_version = payload_version
    end

  private

    attr_reader :content_id, :payload_version
  end
end
