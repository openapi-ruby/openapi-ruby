# frozen_string_literal: true

ENV["APP_ENV"] ||= "test"

require_relative "../app"
require "openapi_ruby/minitest"
require "minitest/autorun"

class ApiTest < Minitest::Test
  include OpenapiRuby::Adapters::Minitest::DSL

  # Including the DSL brings rack-test with it on a non-Rails host; naming the
  # app is the only wiring left.
  def app
    App
  end

  def setup
    PostStore.reset!
  end
end
