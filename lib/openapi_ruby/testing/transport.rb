# frozen_string_literal: true

module OpenapiRuby
  module Testing
    # Bridges the adapters onto whichever request-issuing API the host's test
    # context provides. Rails integration tests take keyword arguments and
    # expose `response`; rack-test (Hanami, Sinatra, bare Rack) takes
    # positional arguments plus a Rack env and exposes `last_response`.
    #
    # Both response objects answer #status, #body and #headers, so callers
    # need no further normalisation.
    module Transport
      # Rails is checked first: a suite can include Rack::Test::Methods
      # alongside the integration helpers, and in that case the Rails session
      # is the one that boots the app under test.
      def self.for(context)
        if context.respond_to?(:integration_session)
          RailsIntegration.new(context)
        elsif context.respond_to?(:last_response)
          require_app!(context)
          RackTest.new(context)
        elsif OpenapiRuby.rails_host?
          # A hand-rolled harness that defines the verb methods itself. Left
          # working rather than second-guessed.
          RailsIntegration.new(context)
        else
          # Without rack-test, dispatch would land on the example-group DSL's
          # own `get`, and the user would get told that `get` is unavailable
          # inside an example — true, and no help at all here.
          raise OpenapiRuby::Error,
            "openapi_ruby found no way to issue requests from #{describe(context)}. " \
            "Add rack-test to your bundle, `include Rack::Test::Methods`, and define `app`."
        end
      end

      # rack-test resolves `app` lazily, so a missing one surfaces as a bare
      # NameError from inside the gem rather than as the setup mistake it is.
      def self.require_app!(context)
        return if context.respond_to?(:app)

        raise OpenapiRuby::Error,
          "openapi_ruby needs the Rack app under test in #{describe(context)}. " \
          "Define it as `let(:app) { MyApp }` in RSpec, or an `app` method in Minitest."
      end

      def self.describe(context)
        context.is_a?(Class) ? context.name.to_s : context.class.name.to_s
      end

      class RailsIntegration
        def initialize(context)
          @context = context
        end

        def dispatch(method, path, params: nil, headers: nil)
          args = {}
          args[:params] = params unless params.nil?
          args[:headers] = headers unless headers.nil?
          @context.send(method.to_sym, path, **args)
        end

        def response
          @context.response
        end
      end

      class RackTest
        # Rack keeps these two out of the HTTP_ namespace.
        UNPREFIXED_HEADERS = {
          "content-type" => "CONTENT_TYPE",
          "content-length" => "CONTENT_LENGTH"
        }.freeze

        def initialize(context)
          @context = context
        end

        # rack-test treats a String `params` as the request body and a Hash as
        # form/query data, which is the same split the adapters already make.
        def dispatch(method, path, params: nil, headers: nil)
          @context.send(method.to_sym, path, params || {}, rack_env(headers || {}))
        end

        def response
          @context.last_response
        end

        private

        def rack_env(headers)
          headers.each_with_object({}) do |(name, value), env|
            key = name.to_s
            env[UNPREFIXED_HEADERS.fetch(key.downcase) { "HTTP_#{key.upcase.tr("-", "_")}" }] = value.to_s
          end
        end
      end
    end
  end
end
