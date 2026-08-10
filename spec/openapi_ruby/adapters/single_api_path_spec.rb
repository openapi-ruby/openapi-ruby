# frozen_string_literal: true

require "spec_helper"
require "openapi_ruby/minitest"

RSpec.describe "one api_path per class" do
  def build_class
    Class.new(::Minitest::Test) do
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :test

      def self.name = "TimersTest"
    end
  end

  around do |example|
    previous = OpenapiRuby.configuration.single_api_path_per_class
    example.run
    OpenapiRuby.configuration.single_api_path_per_class = previous
  end

  context "when enforcement is off (the default)" do
    before { OpenapiRuby.configuration.single_api_path_per_class = false }

    it "allows a second api_path" do
      klass = build_class

      expect {
        klass.api_path("/timers") { get("List") { response(200, "ok") } }
        klass.api_path("/timers/{id}") { get("Show") { response(200, "ok") } }
      }.not_to raise_error

      expect(klass._openapi_contexts.size).to eq(2)
    end

    it "says nothing about it, since resolution handles more than one path" do
      klass = build_class
      klass.api_path("/timers") { get("List") { response(200, "ok") } }

      expect {
        klass.api_path("/timers/{id}") { get("Show") { response(200, "ok") } }
      }.not_to output.to_stderr
    end
  end

  context "when enforcement is on" do
    before { OpenapiRuby.configuration.single_api_path_per_class = true }

    it "allows the first api_path" do
      klass = build_class

      expect { klass.api_path("/timers") { get("List") { response(200, "ok") } } }.not_to raise_error
    end

    it "raises on the second, naming both paths" do
      klass = build_class
      klass.api_path("/timers") { get("List") { response(200, "ok") } }

      expect { klass.api_path("/timers/{id}") { get("Show") { response(200, "ok") } } }
        .to raise_error(OpenapiRuby::MultipleApiPaths, %r{"/timers".*"/timers/\{id\}"})
    end

    it "names the class so the author knows where to split" do
      klass = build_class
      klass.api_path("/timers") { get("List") { response(200, "ok") } }

      expect { klass.api_path("/timers/{id}") { get("Show") { response(200, "ok") } } }
        .to raise_error(OpenapiRuby::MultipleApiPaths, /TimersTest/)
    end
  end
end
