# Represents a data store on Discovery Engine.
#
# A data store contains the indexed documents that can be searched through an engine.
#
# Our architecture currently only has a single data store, so we do not need the ability to manage
# data stores through Search Admin.
#
# see https://cloud.google.com/ruby/docs/reference/google-cloud-discovery_engine-v1/latest/Google-Cloud-DiscoveryEngine-V1-DataStore
DataStore = Data.define(:remote_resource_id) do
  include DiscoveryEngineNameable

  def self.default
    new("govuk_content")
  end

  def parent
    Collection.default
  end
end
