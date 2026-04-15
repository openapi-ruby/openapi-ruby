# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/class/attribute"
require "active_support/core_ext/hash/deep_merge"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/deep_dup"
require "active_support/core_ext/string/inflections"
require "json_schemer"
require "yaml"

require_relative "openapi_rails/version"
require_relative "openapi_rails/errors"
require_relative "openapi_rails/configuration"

module OpenapiRails
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

require_relative "openapi_rails/core/document"
require_relative "openapi_rails/core/document_builder"
require_relative "openapi_rails/core/ref_resolver"
require_relative "openapi_rails/components/key_transformer"
require_relative "openapi_rails/components/registry"
require_relative "openapi_rails/components/base"
require_relative "openapi_rails/components/loader"
