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

    # True when the current process was started by `openapi_ruby:generate`
    # (the rake task sets OPENAPI_RUBY_GENERATING=true in the subprocess).
    #
    # Useful in consumer test helpers to guard test-framework requires
    # that conflict when both `rspec/rails` and `rails/test_help` load
    # in the same process (the FRAMEWORK=hybrid case):
    #
    #   # test/test_helper.rb
    #   unless OpenapiRuby.schema_generating?
    #     require "rails/test_help"
    #     # ...other test-time setup...
    #   end
    def schema_generating?
      ENV["OPENAPI_RUBY_GENERATING"] == "true"
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
if defined?(Rails::Engine)
  require_relative "openapi_ruby/engine"
else
  # Rails wasn't loaded when openapi_ruby was required (e.g. the
  # schema-generation subprocess requires openapi_ruby/rspec before
  # any spec file boots Rails). Defer loading via autoload so the
  # `mount OpenapiRuby::Engine` in routes resolves once Rails arrives.
  module OpenapiRuby
    autoload :Engine, "openapi_ruby/engine"
  end
end
