# frozen_string_literal: true

module OpenapiRuby
  class Configuration
    # Schema definitions — supports multiple schemas (e.g. public_api, admin_api)
    # Each key maps to a hash with :info, :servers, :component_scope, :strict_mode, etc.
    attr_accessor :schemas

    # Components
    attr_accessor :component_paths
    attr_accessor :component_scope_paths

    # Output / formatting
    attr_accessor :camelize_keys, :schema_output_format, :schema_output_dir
    attr_accessor :auto_validation_error_response
    attr_accessor :validation_error_schema

    # Middleware (runtime validation)
    attr_accessor :request_validation, :response_validation, :coerce_params

    # OpenAPI meta-schema validation of generated specs and middleware-loaded
    # documents. One of :disabled, :enabled (raise on errors), :warn_only
    # (default, log warnings). Boolean values are accepted for backwards
    # compatibility: `true` → :warn_only, `false` → :disabled.
    attr_reader :strict_reference_validation

    def strict_reference_validation=(value)
      @strict_reference_validation = case value
      when true, :warn_only then :warn_only
      when false, :disabled then :disabled
      when :enabled then :enabled
      else
        raise ConfigurationError,
          "strict_reference_validation must be :disabled, :enabled, :warn_only, or a boolean"
      end
    end

    # UI (optional)
    attr_accessor :ui_enabled, :ui_path, :ui_config

    def initialize
      @schemas = {}
      @component_paths = ["app/api_components"]
      @component_scope_paths = {}
      @camelize_keys = true
      @request_validation = :disabled
      @response_validation = :disabled
      @coerce_params = true
      @schema_output_dir = "swagger"
      @schema_output_format = :yaml
      @ui_enabled = false
      @ui_path = "/api-docs"
      @ui_config = {}
      @strict_reference_validation = :warn_only
      @auto_validation_error_response = true
      @validation_error_schema = nil
    end

    def validate!
      unless %i[disabled enabled warn_only].include?(@request_validation)
        raise ConfigurationError, "request_validation must be :disabled, :enabled, or :warn_only"
      end

      unless %i[disabled enabled warn_only].include?(@response_validation)
        raise ConfigurationError, "response_validation must be :disabled, :enabled, or :warn_only"
      end

      return if %i[yaml json].include?(@schema_output_format)

      raise ConfigurationError, "schema_output_format must be :yaml or :json"
    end
  end
end
