source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

RAILS_GEMS_VERSION = "7.0.7.2".freeze
gem "actionpack", RAILS_GEMS_VERSION
gem "activemodel", RAILS_GEMS_VERSION
gem "activesupport", RAILS_GEMS_VERSION
gem "railties", RAILS_GEMS_VERSION

gem "bootsnap", require: false
gem "govuk_app_config"

# Gems for publishing_event_pipeline
gem "govuk_message_queue_consumer", require: false
gem "jsonpath", require: false

group :test do
  gem "simplecov", require: false
end

group :development, :test do
  gem "brakeman", require: false
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "govuk_test"
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
end
