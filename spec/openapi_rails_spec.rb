# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRails do
  it "has a version number" do
    expect(OpenapiRails::VERSION).not_to be_nil
  end

  describe ".configure" do
    it "yields the configuration" do
      described_class.configure do |config|
        config.spec_output_format = :json
      end

      expect(described_class.configuration.spec_output_format).to eq(:json)
    end
  end

  describe ".reset_configuration!" do
    it "resets to defaults" do
      described_class.configure { |c| c.spec_output_format = :json }
      described_class.reset_configuration!

      expect(described_class.configuration.spec_output_format).to eq(:yaml)
    end
  end
end
