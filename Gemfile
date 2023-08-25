source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

RAILS_GEMS_VERSION = "7.0.7.2"
gem "railties", RAILS_GEMS_VERSION
gem "actionpack", RAILS_GEMS_VERSION
gem "activemodel", RAILS_GEMS_VERSION
gem "activesupport", RAILS_GEMS_VERSION

gem "puma", "~> 5.0"

group :test do
  gem "simplecov", require: false
end

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "govuk_test"
  gem "rspec-rails"
end
