# frozen_string_literal: true

# Loading a consumer's spec/test files during schema generation must not run
# them. Both frameworks install their runner via an `at_exit` hook that a
# helper pulls in transitively (`rails/test_help` → `Minitest.autorun`,
# `rspec/autorun` → RSpec's), so the suppressor has to neutralise them before
# any consumer file is required.

require "spec_helper"
require "openapi_ruby/generator/autorun_suppressor"

RSpec.describe OpenapiRuby::Generator::AutorunSuppressor do
  describe ".suppress_minitest!" do
    it "stops Minitest.autorun from registering the at_exit hook" do
      minitest = Module.new do
        def self.installed = @installed ||= false

        def self.autorun
          @installed = true
        end
      end
      stub_const("Minitest", minitest)

      described_class.suppress_minitest!
      Minitest.autorun

      expect(Minitest.installed).to be(false)
    end

    it "neutralises Minitest.run for a hook registered before install" do
      minitest = Module.new do
        def self.autorun = nil

        def self.run(*)
          raise "the suite must not run during schema generation"
        end
      end
      stub_const("Minitest", minitest)

      described_class.suppress_minitest!

      expect { Minitest.run([]) }.not_to raise_error
      expect(Minitest.run([])).to be(true)
    end
  end

  describe ".suppress_rspec!" do
    it "disables RSpec's autorun when RSpec is loaded" do
      runner = Class.new do
        def self.disabled = @disabled ||= false

        def self.disable_autorun!
          @disabled = true
        end
      end
      stub_const("RSpec::Core::Runner", runner)

      described_class.suppress_rspec!

      expect(RSpec::Core::Runner.disabled).to be(true)
    end

    it "is a no-op when RSpec is not loaded" do
      hide_const("RSpec::Core::Runner")

      expect { described_class.suppress_rspec! }.not_to raise_error
    end
  end
end
