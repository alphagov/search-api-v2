# Enhances models with a `#name` method returning their fully qualified Google Cloud Platform
# resource name (like a path).
#
# For example, for a `Control`, this would be:
#   projects/{project}/locations/{location}/collections/{collection_id}/engines/
#   {engine_id}/controls/{control_id}
#
# Requires the including class to implement `#remote_resource_id`, and optionally `#parent` if the
# parent resource is not the default collection.
module DiscoveryEngineNameable
  # The name (fully qualified path) of this Discovery Engine resource on GCP
  def name
    [parent_name, resource_path_fragment, remote_resource_id].join("/")
  end

private

  def resource_path_fragment
    # For example: `DataStore` -> `dataStores`
    self.class.name.downcase_first.pluralize
  end

  def parent_name
    if respond_to?(:parent)
      parent.name
    else
      # The default location is the parent of all root-level resources
      Rails.configuration.discovery_engine_default_location_name
    end
  end
end
