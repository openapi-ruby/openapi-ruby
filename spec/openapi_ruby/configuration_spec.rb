# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "sets schemas to empty hash" do
      expect(config.schemas).to eq({})
    end

    it "sets component_paths" do
      expect(config.component_paths).to eq(["app/api_components"])
    end

    it "enables camelize_keys" do
      expect(config.camelize_keys).to be true
    end

    it "disables request_validation" do
      expect(config.request_validation).to eq(:disabled)
    end

    it "disables response_validation" do
      expect(config.response_validation).to eq(:disabled)
    end

    it "enables coerce_params" do
      expect(config.coerce_params).to be true
    end

    it "sets schema_output_dir to swagger" do
      expect(config.schema_output_dir).to eq("swagger")
    end

    it "sets schema_output_format to yaml" do
      expect(config.schema_output_format).to eq(:yaml)
    end

    it "disables ui" do
      expect(config.ui_enabled).to be false
    end

    it "sets ui_path" do
      expect(config.ui_path).to eq("/api-docs")
    end
  end

  describe "#validate!" do
    it "accepts valid request_validation values" do
      %i[disabled enabled warn_only].each do |val|
        config.request_validation = val
        expect { config.validate! }.not_to raise_error
      end
    end

    it "rejects invalid request_validation" do
      config.request_validation = :invalid
      expect { config.validate! }.to raise_error(OpenapiRuby::ConfigurationError)
    end

    it "rejects invalid response_validation" do
      config.response_validation = :invalid
      expect { config.validate! }.to raise_error(OpenapiRuby::ConfigurationError)
    end

    it "rejects invalid schema_output_format" do
      config.schema_output_format = :xml
      expect { config.validate! }.to raise_error(OpenapiRuby::ConfigurationError)
    end
  end
end
