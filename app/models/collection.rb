# Represents a collection on Discovery Engine.
#
# A collection is a logical grouping that contains other resources like engines and data stores.
# Currently, Discovery Engine uses a single default collection with no ability to create further
# ones.
Collection = Data.define(:remote_resource_id) do
  include DiscoveryEngineNameable

  # The default collection
  def self.default
    new("default_collection")
  end
end
