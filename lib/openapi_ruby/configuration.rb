# frozen_string_literal: true

module OpenapiRuby
  class Configuration
    # Schema definitions — supports multiple schemas (e.g. public_api, admin_api)
    # Each key maps to a hash with :info, :servers, :component_scope, :strict_mode, etc.
    attr_accessor :schemas

    # Components
    attr_accessor :component_paths
    attr_accessor :component_scope_paths
    attr_accessor :camelize_keys, :key_transform, :response_validation, :strict_query_params,
      :coerce_params, :error_handler, :schema_output_format, :validate_responses_in_tests, :ui_path, :ui_config, :coverage_report_path
    attr_accessor :strict_reference_validation

    # Middleware (runtime validation)
    attr_accessor :request_validation

    # Test / Generation
    attr_accessor :schema_output_dir

    # UI (optional)
    attr_accessor :ui_enabled

    # Coverage
    attr_accessor :coverage_enabled

    def initialize
      @schemas = {}
      @component_paths = ["app/api_components"]
      @component_scope_paths = {}
      @camelize_keys = true
      @key_transform = nil
      @request_validation = :disabled
      @response_validation = :disabled
      @strict_query_params = false
      @coerce_params = true
      @error_handler = nil
      @schema_output_dir = "swagger"
      @schema_output_format = :yaml
      @validate_responses_in_tests = true
      @ui_enabled = false
      @ui_path = "/api-docs"
      @ui_config = {}
      @strict_reference_validation = true
      @coverage_enabled = false
      @coverage_report_path = "tmp/openapi_coverage.json"
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
