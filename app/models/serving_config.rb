# Represents a serving config on Discovery Engine.
#
# A serving config is an endpoint on an engine that can be used for
# querying. Each serving config can have different configuration (in particular, different sets of
# active controls), which allows us to test out new configuration changes outside of the default
# serving config.
#
# see https://cloud.google.com/ruby/docs/reference/google-cloud-discovery_engine-v1beta/latest/Google-Cloud-DiscoveryEngine-V1beta-ServingConfig
ServingConfig = Data.define(:remote_resource_id) do
  include DiscoveryEngineNameable

  # The default serving config automatically available on an engine
  def self.default
    new("default_search")
  end

  def parent
    # We only use a single engine in our architecture, so we can hardcode it here.
    Engine.default
  end
end
