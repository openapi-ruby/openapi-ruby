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

  # Generated output goes to tmp/ so it never overwrites the hand-maintained
  # openapi/public_api.yaml the middleware loads at boot.
  config.schema_output_dir = "tmp/openapi"
end
