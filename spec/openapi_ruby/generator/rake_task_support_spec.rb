# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe OpenapiRuby::Generator::RakeTaskSupport do
  describe ".detect_host" do
    it "detects Rails in a Rails app" do
      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p(File.join(dir, "config"))
        FileUtils.touch(File.join(dir, "config", "application.rb"))

        Dir.chdir(dir) { expect(described_class.detect_host).to eq("rails") }
      end
    end

    it "detects Hanami from its app class location" do
      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p(File.join(dir, "config"))
        FileUtils.touch(File.join(dir, "config", "app.rb"))

        Dir.chdir(dir) { expect(described_class.detect_host).to eq("hanami") }
      end
    end

    it "detects Hanami when it is already loaded" do
      stub_const("Hanami", Module.new)

      expect(described_class.detect_host).to eq("hanami")
    end
  end

  describe ".subprocess_env" do
    it "defaults the Rails environment to test and flags generation" do
      expect(described_class.subprocess_env("rails")).to eq(
        "RAILS_ENV" => "test",
        "OPENAPI_RUBY_GENERATING" => "true"
      )
    end

    it "sets HANAMI_ENV for a Hanami host" do
      expect(described_class.subprocess_env("hanami")).to eq(
        "HANAMI_ENV" => "test",
        "OPENAPI_RUBY_GENERATING" => "true"
      )
    end

    it "honours an explicitly set host environment" do
      ENV["HANAMI_ENV"] = "staging"

      expect(described_class.subprocess_env("hanami")).to include("HANAMI_ENV" => "staging")
    ensure
      ENV.delete("HANAMI_ENV")
    end
  end
end
