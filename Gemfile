source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

RAILS_GEMS_VERSION = "8.1.2".freeze
gem "actionpack", RAILS_GEMS_VERSION
gem "activemodel", RAILS_GEMS_VERSION
gem "activesupport", RAILS_GEMS_VERSION
gem "railties", RAILS_GEMS_VERSION

gem "benchmark"
gem "bootsnap", require: false
gem "connection_pool"
gem "csv"
gem "google-cloud-discovery_engine"
gem "govuk_app_config"
gem "govuk_message_queue_consumer"
gem "jsonpath"
gem "loofah"
gem "prometheus-client"
gem "redis"
gem "redlock"

group :test do
  gem "climate_control"
  gem "grpc_mock"
  gem "json_schemer"
  gem "simplecov", require: false
  gem "timecop"
end

group :development, :test do
  gem "brakeman", require: false
  gem "googleauth", ">= 1.16.0"
  gem "govuk_test"
  gem "pry-byebug"
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
end
