# frozen_string_literal: true

require "openapi_ruby"

OpenapiRuby.configure do |config|
  config.schemas = {
    public_api: {
      info: {title: "Sinatra Dummy API", version: "1.0.0"},
      servers: [{url: "/api/v1"}],
      # Scopes the validation middleware to the API, leaving the mounted
      # /api-docs endpoints alone.
      prefix: "/api/v1"
    }
  }

  config.camelize_keys = false
  config.request_validation = :enabled
  config.response_validation = :enabled
  config.ui_enabled = true

  # A Rack app has no autoload convention to hook into, so components are
  # loaded from wherever they are put — this path is relative to the app root.
  config.component_paths = ["api_components"]
end
