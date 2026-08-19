# frozen_string_literal: true

require "openapi_ruby/hanami"

OpenapiRuby.configure do |config|
  config.schemas = {
    public_api: {
      info: {title: "Hanami Dummy API", version: "1.0.0"},
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

  # Default "openapi" — the same directory the middleware loads at boot and the
  # mounted endpoints serve from, so `rake openapi_ruby:generate` regenerating
  # the committed document is exactly what should happen here.
  config.schema_output_dir = "openapi"
end
