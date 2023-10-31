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

    # Google Discovery Engine configuration (overridden in test environment)
    unless Rails.env.test?
      config.discovery_engine_serving_config = ENV.fetch("DISCOVERY_ENGINE_SERVING_CONFIG")

      require "repositories/google_discovery_engine/read_repository"
      config.repository_class = Repositories::GoogleDiscoveryEngine::ReadRepository
    end
  end
end
