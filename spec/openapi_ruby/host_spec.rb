# frozen_string_literal: true

require "spec_helper"
require_relative "../support/rails_app"

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
