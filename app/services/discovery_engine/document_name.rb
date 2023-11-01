module DiscoveryEngine
  module DocumentName
    DEFAULT_BRANCH = "/branches/default_branch".freeze

    def document_name(content_id)
      branch_path = Rails.configuration.discovery_engine_datastore + DEFAULT_BRANCH
      "#{branch_path}/documents/#{content_id}"
    end
  end
end
