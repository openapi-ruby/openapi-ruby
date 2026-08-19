# frozen_string_literal: true

require "openapi_ruby"

module OpenapiRuby
  # Hanami 2 integration. Rails receives this wiring from the engine's
  # initializer and from rspec-rails; Hanami has no engines, so the host app
  # makes the calls itself.
  #
  # ::Hanami is spelled with leading colons throughout — inside this namespace
  # a bare `Hanami` would resolve to OpenapiRuby::Hanami.
  module Hanami
    # Included into :openapi example groups so rack-test knows which app to
    # drive. A `let(:app)` in the suite takes precedence over this.
    module RackTestApp
      def app
        ::Hanami.app
      end
    end

    module_function

    # Mounts the runtime validation middleware. In config/app.rb, after
    # requiring the file that holds your OpenapiRuby.configure block:
    #
    #   module MyApp
    #     class App < Hanami::App
    #       OpenapiRuby::Hanami.install_middleware!(config)
    #     end
    #   end
    #
    # Takes the app config (preferred — it carries the root) or a bare
    # middleware stack.
    def install_middleware!(config, root: nil)
      stack = config.respond_to?(:middleware) ? config.middleware : config
      root ||= config_root(config) || OpenapiRuby.app_root

      Middleware::Installer.install!(stack, root: root)
    end

    # Wires rack-test into :openapi example groups. Called for you by
    # `require "openapi_ruby/rspec"`; exposed for suites that configure RSpec
    # by hand.
    def install_rspec!(rspec_config = nil)
      require "rack/test"

      wire = lambda do |config|
        config.include ::Rack::Test::Methods, type: :openapi
        config.include RackTestApp, type: :openapi
      end

      rspec_config ? wire.call(rspec_config) : ::RSpec.configure(&wire)
    end

    def config_root(config)
      root = config.respond_to?(:root) ? config.root : nil
      root unless root.to_s.empty?
    end

    # Requiring this file declares the host, so the component default no longer
    # depends on ::Hanami being loaded before the configuration object was
    # built. Only a pristine default is replaced.
    def apply_component_path_default!
      config = OpenapiRuby.configuration
      return unless config.component_paths == Configuration::RAILS_COMPONENT_PATHS

      config.component_paths = Configuration::HANAMI_COMPONENT_PATHS.dup
    end
  end
end

OpenapiRuby::Hanami.apply_component_path_default!
