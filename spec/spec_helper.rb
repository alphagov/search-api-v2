ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start "rails"

require File.expand_path("../config/environment", __dir__)
require "rspec/rails"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
GovukTest.configure

require "grpc_mock/rspec"

# Required to be able to stub Google classes in tests (as classes from the `v1` namespace are not
# used directly in non-test code, they are not loaded by default)
require "google/cloud/discovery_engine/v1"

Timecop.safe_mode = true

require "redlock/testing"
Redlock::Client.testing_mode = :bypass

Rails.application.load_tasks

# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.default_formatter = "doc" if config.files_to_run.one?
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.expose_dsl_globally = false
  config.infer_spec_type_from_file_location!
  config.profile_examples = 10
  config.shared_context_metadata_behavior = :apply_to_host_groups # Preempting v4 default

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true # Preempting v4 default
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true # Preempting v4 default
  end

  config.include FixtureHelpers

  GrpcMock.disable_net_connect!
end
