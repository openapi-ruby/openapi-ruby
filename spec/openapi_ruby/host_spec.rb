# frozen_string_literal: true

require "spec_helper"
require_relative "../support/rails_app"

RSpec.describe "OpenapiRuby host detection" do
  describe ".host" do
    it "is :rails when Rails is loaded" do
      expect(OpenapiRuby.host).to eq(:rails)
      expect(OpenapiRuby).to be_rails_host
    end

    it "is :hanami when only Hanami is loaded" do
      hide_const("Rails")
      stub_const("Hanami", Module.new)

      expect(OpenapiRuby.host).to eq(:hanami)
      expect(OpenapiRuby).to be_hanami_host
    end

    # Sinatra, Roda, bare Rack — anything whose only shared surface is Rack.
    it "is :rack with no framework loaded" do
      hide_const("Rails")

      expect(OpenapiRuby.host).to eq(:rack)
      expect(OpenapiRuby).to be_rack_host
    end

    # A Rails app with another framework's gems in the bundle is still Rails.
    it "prefers Rails when both constants are present" do
      stub_const("Hanami", Module.new)

      expect(OpenapiRuby.host).to eq(:rails)
    end
  end
end

RSpec.describe "OpenapiRuby.app_root" do
  it "uses the Rails root when Rails is booted" do
    expect(OpenapiRuby.app_root).to eq(Rails.root.to_s)
  end

  it "uses the Hanami app root when Hanami is booted" do
    hide_const("Rails")
    stub_const("Hanami", Module.new do
      def self.app? = true

      def self.app = Struct.new(:root).new("/srv/hanami_app")
    end)

    expect(OpenapiRuby.app_root).to eq("/srv/hanami_app")
  end

  # The schema-generation subprocess loads test files without booting an app.
  it "falls back to the working directory with no host framework" do
    hide_const("Rails")

    expect(OpenapiRuby.app_root).to eq(Dir.pwd)
  end

  it "ignores a Hanami constant with no app registered" do
    hide_const("Rails")
    stub_const("Hanami", Module.new { def self.app? = false })

    expect(OpenapiRuby.app_root).to eq(Dir.pwd)
  end
end
