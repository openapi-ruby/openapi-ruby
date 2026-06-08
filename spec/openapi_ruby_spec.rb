# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby do
  it "has a version number" do
    expect(OpenapiRuby::VERSION).not_to be_nil
  end

  describe ".configure" do
    it "yields the configuration" do
      described_class.configure do |config|
        config.schema_output_format = :json
      end

      expect(described_class.configuration.schema_output_format).to eq(:json)
    end
  end

  describe ".reset_configuration!" do
    it "resets to defaults" do
      described_class.configure { |c| c.schema_output_format = :json }
      described_class.reset_configuration!

      expect(described_class.configuration.schema_output_format).to eq(:yaml)
    end
  end

  describe ".schema_generating?" do
    around do |example|
      original = ENV["OPENAPI_RUBY_GENERATING"]
      example.run
    ensure
      ENV["OPENAPI_RUBY_GENERATING"] = original
    end

    it "is true when OPENAPI_RUBY_GENERATING is 'true'" do
      ENV["OPENAPI_RUBY_GENERATING"] = "true"
      expect(described_class.schema_generating?).to be(true)
    end

    it "is false when OPENAPI_RUBY_GENERATING is unset" do
      ENV.delete("OPENAPI_RUBY_GENERATING")
      expect(described_class.schema_generating?).to be(false)
    end

    it "is false for any other value" do
      ENV["OPENAPI_RUBY_GENERATING"] = "1"
      expect(described_class.schema_generating?).to be(false)
    end
  end
end
