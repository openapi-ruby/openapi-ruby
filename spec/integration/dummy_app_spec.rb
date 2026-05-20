# frozen_string_literal: true

# Boots the dummy Rails app and runs its RSpec request specs as part of the
# gem's test suite. Proves the gem works end-to-end in a real Rails app.

require "spec_helper"
require_relative "../support/rails_app"
require "rspec/rails"

# Add the dummy app's spec dir to load path so `require "openapi_helper"` works
$LOAD_PATH.unshift File.expand_path("../dummy/spec", __dir__)

# Load the dummy app's request specs
require_relative "../dummy/spec/requests/users_spec"
require_relative "../dummy/spec/requests/response_validation_spec"
