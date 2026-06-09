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

    it "defaults strict_reference_validation to :warn_only" do
      expect(config.strict_reference_validation).to eq(:warn_only)
    end

    it "enables test_request_validation by default" do
      expect(config.test_request_validation).to be true
    end
  end

  describe "#strict_reference_validation=" do
    it "accepts :disabled, :enabled, :warn_only" do
      %i[disabled enabled warn_only].each do |val|
        config.strict_reference_validation = val
        expect(config.strict_reference_validation).to eq(val)
      end
    end

    it "maps legacy true to :warn_only" do
      config.strict_reference_validation = true
      expect(config.strict_reference_validation).to eq(:warn_only)
    end

    it "maps legacy false to :disabled" do
      config.strict_reference_validation = false
      expect(config.strict_reference_validation).to eq(:disabled)
    end

    it "rejects unknown values" do
      expect { config.strict_reference_validation = :nope }
        .to raise_error(OpenapiRuby::ConfigurationError)
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
