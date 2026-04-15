# frozen_string_literal: true

module OpenapiRails
  class Configuration
    # Spec definitions — supports multiple specs (e.g. public, admin, internal)
    # Each key maps to a hash with :info, :servers, :component_scope, etc.
    attr_accessor :specs

    # Components
    attr_accessor :component_paths
    attr_accessor :camelize_keys
    attr_accessor :key_transform

    # Middleware (runtime validation)
    attr_accessor :request_validation
    attr_accessor :response_validation
    attr_accessor :strict_mode
    attr_accessor :strict_query_params
    attr_accessor :coerce_params
    attr_accessor :error_handler

    # Test / Generation
    attr_accessor :spec_output_dir
    attr_accessor :spec_output_format
    attr_accessor :validate_responses_in_tests

    # UI (optional)
    attr_accessor :ui_enabled
    attr_accessor :ui_path
    attr_accessor :ui_config

    # Coverage
    attr_accessor :coverage_enabled
    attr_accessor :coverage_report_path

    def initialize
      @specs = {}
      @component_paths = ["app/api_components"]
      @camelize_keys = true
      @key_transform = nil
      @request_validation = :disabled
      @response_validation = :disabled
      @strict_mode = false
      @strict_query_params = false
      @coerce_params = true
      @error_handler = nil
      @spec_output_dir = "swagger"
      @spec_output_format = :yaml
      @validate_responses_in_tests = true
      @ui_enabled = false
      @ui_path = "/api-docs"
      @ui_config = {}
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

      unless %i[yaml json].include?(@spec_output_format)
        raise ConfigurationError, "spec_output_format must be :yaml or :json"
      end
    end
  end
end
