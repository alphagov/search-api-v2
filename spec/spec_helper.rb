ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start "rails"

require File.expand_path("../config/environment", __dir__)
require "rspec/rails"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
GovukTest.configure

# TODO: If the write side of this application is extracted to a separate unit, we will need to
#   remove this, otherwise it can be made permanent.
require "document_sync_worker"

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
end
