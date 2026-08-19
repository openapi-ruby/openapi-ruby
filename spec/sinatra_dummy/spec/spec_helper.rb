# frozen_string_literal: true

# Sinatra only relaxes its host authorization outside development, so without
# this rack-test's default Host header is rejected with a 403.
ENV["APP_ENV"] ||= "test"

require_relative "../app"
require "openapi_ruby/rspec"

# A Rack host has no convention for which app is under test, so the suite says.
# `let(:app) { App }` in an individual group does the same job.
module AppUnderTest
  def app
    App
  end
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random

  config.include AppUnderTest, type: :openapi

  config.before { PostStore.reset! }
end
