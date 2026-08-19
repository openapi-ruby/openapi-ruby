# frozen_string_literal: true

require "hanami"
require_relative "openapi_ruby"

module HanamiDummy
  class App < Hanami::App
    # Declared before :body_parser so the validation middleware reads (and
    # rewinds) the request body first.
    OpenapiRuby::Hanami.install_middleware!(config)

    config.middleware.use :body_parser, :json
  end
end
