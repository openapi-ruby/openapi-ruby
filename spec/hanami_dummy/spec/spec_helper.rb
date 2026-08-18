# frozen_string_literal: true

ENV["HANAMI_ENV"] ||= "test"

require "hanami/prepare"
require "openapi_ruby/rspec"

RSpec.configure do |config|
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random

  config.before { HanamiDummy::PostStore.reset! }
end
