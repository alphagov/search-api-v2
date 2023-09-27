module PublishingEventPipeline
  module Extractors
    # Extracts indexable unstructured content from a publishing event
    class Content
      # Returns a string of unstructured content
      def call(message_hash)
        # TODO: Eventually, this should do something more sophisticated along the lines of what the
        # existing search-api does in `lib/govuk_index/presenters/indexable_content_presenter.rb`, but
        # this is a decent enough MVP for now.
        message_hash.dig("details", "body")
      end
    end
  end
end
