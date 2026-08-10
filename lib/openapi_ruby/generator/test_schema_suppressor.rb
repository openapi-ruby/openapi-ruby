# frozen_string_literal: true

module OpenapiRuby
  module Generator
    # Schema generation never runs tests, so keeping the test database's schema
    # current is wasted work — but `rails/test_help` does it unconditionally at
    # require time (`rails/testing/maintain_test_schema` → `maintain_test_schema!`),
    # which opens a database connection. That makes a database a hard
    # requirement for generating a document that doesn't depend on one.
    #
    # `maintain_test_schema!` is a no-op when the setting is off, so turning it
    # off for the generation subprocess drops the requirement.
    #
    # This only skips the schema *check*. A connection is still available if the
    # consumer's declarations genuinely need one (say, an enum built from a
    # query at load time) — such a suite needs a database either way.
    module TestSchemaSuppressor
      module_function

      def install!
        return unless defined?(::ActiveSupport) && ::ActiveSupport.respond_to?(:on_load)

        # Registered as a load hook so it applies whenever the consumer's helper
        # boots Rails, rather than depending on require order.
        ::ActiveSupport.on_load(:active_record) do
          OpenapiRuby::Generator::TestSchemaSuppressor.disable!
        end
      end

      # Neutralises the methods rather than clearing
      # `ActiveRecord.maintain_test_schema`. The flag is reapplied from app
      # config by the `active_record.set_configs` initializer, which runs after
      # any load hook we can register from here — so setting it is silently
      # undone before `rails/test_help` reads it.
      def disable!
        ::ActiveRecord::Migration.singleton_class.prepend(MigrationSilencer)
      end

      module MigrationSilencer
        # Called by rails/test_help at require time.
        def maintain_test_schema!
          nil
        end

        # Not called by Rails during boot, but a common addition to a
        # hand-written test_helper. Same intent as the above: assert the test
        # database matches the migrations. Nothing is loaded from the database
        # to build the document, so there is nothing to verify.
        def check_all_pending!
          nil
        end
      end
    end
  end
end
