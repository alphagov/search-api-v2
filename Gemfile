source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.1"

RAILS_GEMS_VERSION = "~> 7.1.3".freeze
gem "actionpack", RAILS_GEMS_VERSION
gem "activemodel", RAILS_GEMS_VERSION
gem "activesupport", RAILS_GEMS_VERSION
gem "railties", RAILS_GEMS_VERSION

gem "bootsnap", require: false
gem "connection_pool"
gem "google-cloud-discovery_engine"
gem "govuk_app_config"
gem "govuk_message_queue_consumer"
gem "jsonpath"
gem "loofah"
gem "prometheus-client"
gem "redis"
gem "redlock"

group :test do
  gem "grpc_mock"
  gem "json_schemer"
  gem "simplecov", require: false
  gem "timecop"
end

group :development, :test do
  gem "brakeman", require: false
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "govuk_test"
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
end
