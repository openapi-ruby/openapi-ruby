# frozen_string_literal: true

require_relative "app"

# The docs endpoints are a plain Rack app, so they mount like any other.
map "/api-docs" do
  run OpenapiRuby::RackApp
end

map "/" do
  run App
end
