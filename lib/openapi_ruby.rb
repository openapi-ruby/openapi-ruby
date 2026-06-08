# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/class/attribute"
require "active_support/core_ext/hash/deep_merge"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/deep_dup"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/string/inflections"
require "json_schemer"
require "yaml"

require_relative "openapi_ruby/version"
require_relative "openapi_ruby/errors"
require_relative "openapi_ruby/configuration"

module OpenapiRuby
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

require_relative "openapi_ruby/core/document"
require_relative "openapi_ruby/core/document_builder"
require_relative "openapi_ruby/core/ref_resolver"
require_relative "openapi_ruby/components/key_transformer"
require_relative "openapi_ruby/components/registry"
require_relative "openapi_ruby/components/base"
require_relative "openapi_ruby/components/loader"
require_relative "openapi_ruby/dsl/response_context"
require_relative "openapi_ruby/dsl/operation_context"
require_relative "openapi_ruby/dsl/context"
require_relative "openapi_ruby/dsl/metadata_store"
require_relative "openapi_ruby/testing/request_builder"
require_relative "openapi_ruby/testing/response_validator"
require_relative "openapi_ruby/testing/request_validator"
require_relative "openapi_ruby/testing/assertions"
require_relative "openapi_ruby/testing/coverage"
require_relative "openapi_ruby/generator/schema_writer"
require_relative "openapi_ruby/generator/rake_task_support"
require_relative "openapi_ruby/middleware/path_matcher"
require_relative "openapi_ruby/middleware/coercion"
require_relative "openapi_ruby/middleware/error_handler"
require_relative "openapi_ruby/middleware/schema_resolver"
require_relative "openapi_ruby/middleware/request_validation"
require_relative "openapi_ruby/middleware/response_validation"
require_relative "openapi_ruby/controller_helpers"
require_relative "openapi_ruby/engine" if defined?(Rails::Engine)
