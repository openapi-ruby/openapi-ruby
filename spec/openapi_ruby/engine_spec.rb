# frozen_string_literal: true

require "spec_helper"
require_relative "../support/rails_app"
require "openapi_ruby/engine"

RSpec.describe OpenapiRuby::Engine do
  it "is a Rails::Engine" do
    expect(described_class.superclass).to eq(Rails::Engine)
  end

  it "has an isolated namespace" do
    expect(described_class.isolated?).to be true
  end

  describe "deferred loading" do
    # The hybrid schema-generation script requires openapi_ruby/rspec
    # before any spec file boots Rails. At that point Rails::Engine is
    # not defined, so the eager `require_relative "openapi_ruby/engine"`
    # would be skipped — and routes referencing `OpenapiRuby::Engine`
    # later would raise NameError. The fallback autoload covers that.
    it "resolves OpenapiRuby::Engine when Rails loads after openapi_ruby" do
      lib_path = File.expand_path("../../lib", __dir__)
      script = <<~RUBY
        $LOAD_PATH.unshift(#{lib_path.inspect})
        require "openapi_ruby"
        raise "Rails should not be loaded yet" if defined?(Rails::Engine)
        require "rails"
        require "rails/engine"
        # First reference to the constant — must resolve via autoload.
        OpenapiRuby::Engine
        puts "ok"
      RUBY

      output = IO.popen([RbConfig.ruby, "-e", script], err: [:child, :out], &:read)
      expect(output).to include("ok"), "subprocess failed:\n#{output}"
    end
  end
end
