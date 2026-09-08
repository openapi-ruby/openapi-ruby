# frozen_string_literal: true

# Load the dummy Rails app for specs that need Rails (generators, engine, integration)
ENV["RAILS_ENV"] ||= "test"
require_relative "../dummy/config/environment"

# Set up the in-memory database
ActiveRecord::Schema.verbose = false
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
load File.expand_path("../dummy/db/schema.rb", __dir__)

# The suite resets OpenapiRuby's configuration before every example, which also
# drops whatever the dummy app's initializer set. Parameter naming is
# config-driven, so the dummy's `camelize_keys = false` has to survive that
# reset for its own specs: its controllers and its committed schema are
# snake_case, and camelCased query params would never reach them.
RSpec.configure do |config|
  config.before do |example|
    next unless example.metadata[:absolute_file_path].to_s.include?("/spec/dummy/")

    OpenapiRuby.configuration.camelize_keys = false
  end
end
