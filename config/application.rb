require_relative "boot"

require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SearchApiV2
  class Application < Rails::Application
    config.load_defaults 7.0
    config.time_zone = "London"
    config.api_only = true

    # Google Discovery Engine configuration
    config.discovery_engine_serving_config = ENV.fetch("DISCOVERY_ENGINE_SERVING_CONFIG")
    config.discovery_engine_datastore_branch = ENV.fetch("DISCOVERY_ENGINE_DATASTORE_BRANCH")

    # Document sync configuration
    config.document_type_ignorelist = config_for(:document_type_ignorelist)
    config.document_type_ignorelist_path_overrides = config_for(
      :document_type_ignorelist_path_overrides,
    )
  end
end
