# frozen_string_literal: true

# `rails/test_help` calls `maintain_test_schema!` at require time, which opens a
# database connection. Generating a document that doesn't depend on the database
# shouldn't require one, so the generation subprocess turns the setting off.

require "spec_helper"
require "openapi_ruby/generator/test_schema_suppressor"

RSpec.describe OpenapiRuby::Generator::TestSchemaSuppressor do
  describe ".disable!" do
    let(:migration) do
      Class.new do
        def self.connected = @connected ||= false

        def self.maintain_test_schema!
          @connected = true
          raise "would have opened a database connection"
        end

        def self.check_all_pending!
          @connected = true
          raise "would have opened a database connection"
        end
      end
    end

    before { stub_const("ActiveRecord::Migration", migration) }

    it "makes maintain_test_schema! a no-op" do
      described_class.disable!

      expect { ActiveRecord::Migration.maintain_test_schema! }.not_to raise_error
      expect(ActiveRecord::Migration.connected).to be(false)
    end

    it "makes check_all_pending! a no-op" do
      described_class.disable!

      expect { ActiveRecord::Migration.check_all_pending! }.not_to raise_error
      expect(ActiveRecord::Migration.connected).to be(false)
    end

    it "is idempotent" do
      2.times { described_class.disable! }

      expect { ActiveRecord::Migration.maintain_test_schema! }.not_to raise_error
      expect(ActiveRecord::Migration.connected).to be(false)
    end
  end

  describe ".install!" do
    it "defers to an active_record load hook rather than requiring load order" do
      hooks = []
      active_support = Module.new do
        define_singleton_method(:on_load) { |name, &block| hooks << [name, block] }
      end
      stub_const("ActiveSupport", active_support)

      described_class.install!

      expect(hooks.map(&:first)).to eq([:active_record])
    end

    it "is a no-op when ActiveSupport is absent" do
      hide_const("ActiveSupport")

      expect { described_class.install! }.not_to raise_error
    end
  end
end
