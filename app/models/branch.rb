# Represents a branch on a Discovery Engine data store.
#
# Currently, every data store on Discovery Engine has exactly *one* branch (the default branch), and
# we are not able to make any changes to that resource. However, we still need to model it here
# because documents are children of the branch, not the datastore itself.
#
# see https://cloud.google.com/ruby/docs/reference/google-cloud-discovery_engine-v1/latest/Google-Cloud-DiscoveryEngine-V1-DocumentService-Client
# (there is no documentation specific to branches)
Branch = Data.define(:remote_resource_id) do
  include DiscoveryEngineNameable

  # The default branch automatically available on a data store
  def self.default
    new("default_branch")
  end

  def parent
    # We only use a single data store in our architecture, so we can hardcode it here.
    DataStore.default
  end
end
