module DiscoveryEngine
  module Logging
    def log(level, message, content_id:, payload_version:)
      combined_message = sprintf(
        "[%s] %s content_id:%s payload_version:%d",
        self.class.name,
        message,
        content_id,
        payload_version,
      )
      Rails.logger.add(level, combined_message)
    end
  end
end
