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
    config.load_defaults 8.0
    config.govuk_time_zone = "London"
    config.api_only = true

    # Google Discovery Engine configuration
    config.discovery_engine_default_collection_name = ENV.fetch("DISCOVERY_ENGINE_DEFAULT_COLLECTION_NAME")
    config.discovery_engine_serving_config = ENV.fetch("DISCOVERY_ENGINE_SERVING_CONFIG")
    config.google_cloud_project_id = ENV.fetch("GOOGLE_CLOUD_PROJECT_ID")

    # Document sync configuration
    config.document_type_ignorelist = config_for(:document_type_ignorelist)
    config.document_type_ignorelist_path_overrides = config_for(
      :document_type_ignorelist_path_overrides,
    )

    # Query configuration
    config.best_bets = config_for(:best_bets)

    # Redis configuration
    config.redis_url = ENV.fetch("REDIS_URL")
    config.redis_pool = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: config.redis_url) }

    # Redlock configuration
    ## Note: Redlock allows us to specify multiple Redis URLs for distributed locking, but we're
    ## currently only using a single instance (the Publishing "shared" Redis). If we ever need to
    ## use multiple Redis instances, this is the only place that needs updating.
    config.redlock_redis_instances = [config.redis_url]

    # Feature flags
    def self.feature_flag(name, default: false)
      ActiveModel::Type::Boolean.new.cast(ENV.fetch(name, default))
    end
    config.enable_autocomplete = feature_flag("ENABLE_AUTOCOMPLETE", default: true)
  end
end
