# frozen_string_literal: true

module OpenapiRuby
  module Generator
    # Schema generation loads the consumer's spec/test files purely to collect
    # their `path` / `api_path` declarations. Loading them must not also *run*
    # them.
    #
    # Both frameworks install an `at_exit` hook that runs the suite as a side
    # effect of being required, and a consumer's helper almost always pulls one
    # in transitively — `rails/test_help` requires
    # `active_support/testing/autorun`, which calls `Minitest.autorun`; RSpec
    # does the same via `rspec/autorun`. Without this, `rake openapi_ruby:generate`
    # runs the entire suite and fails whenever any unrelated test fails.
    #
    # Installed by the generated script *before* any consumer file is required,
    # so the hook is never registered in the first place.
    module AutorunSuppressor
      module_function

      def install!
        suppress_minitest!
        suppress_rspec!
      end

      def suppress_minitest!
        require "minitest"

        ::Minitest.singleton_class.prepend(MinitestSilencer)
      rescue LoadError
        # Minitest isn't in the bundle — nothing to suppress.
      end

      def suppress_rspec!
        return unless defined?(::RSpec::Core::Runner)

        ::RSpec::Core::Runner.disable_autorun!
      end

      module MinitestSilencer
        # Swallow the `at_exit` registration. Defined as a no-op rather than
        # setting `@@installed_at_exit` so this doesn't depend on Minitest's
        # internals.
        def autorun
          nil
        end

        # Belt and braces: if something registered the hook before this module
        # was installed, the hook still fires but finds nothing to do.
        def run(*)
          true
        end
      end
    end
  end
end
