# frozen_string_literal: true

OpenapiRuby.configure do |config|
  config.schemas = {
    public_api: {
      info: {title: "Dummy API", version: "1.0.0"},
      servers: [{url: "/"}]
    }
  }

  config.component_paths = [Rails.root.join("app/api_components").to_s]
  config.camelize_keys = false
  # Use tmp dir for generated output so we don't overwrite the hand-maintained swagger/public_api.yaml
  config.schema_output_dir = Rails.root.join("tmp/swagger").to_s
  config.schema_output_format = :yaml
end
