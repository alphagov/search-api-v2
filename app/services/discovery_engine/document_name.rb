module DiscoveryEngine
  module DocumentName
    def document_name(content_id)
      "#{Rails.configuration.discovery_engine_datastore_branch}/documents/#{content_id}"
    end
  end
end
