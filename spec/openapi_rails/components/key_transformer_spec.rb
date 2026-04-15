# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRails::Components::KeyTransformer do
  describe ".camelize" do
    it "converts snake_case to camelCase" do
      expect(described_class.camelize("created_at")).to eq("createdAt")
    end

    it "handles single words" do
      expect(described_class.camelize("name")).to eq("name")
    end

    it "handles multiple underscores" do
      expect(described_class.camelize("first_name_value")).to eq("firstNameValue")
    end

    it "preserves $ref keys" do
      expect(described_class.camelize("$ref")).to eq("$ref")
    end
  end

  describe ".camelize_keys" do
    it "transforms hash keys" do
      input = { "created_at" => "value", "first_name" => "Jane" }
      expected = { "createdAt" => "value", "firstName" => "Jane" }

      expect(described_class.camelize_keys(input)).to eq(expected)
    end

    it "transforms nested hashes" do
      input = { "user_info" => { "first_name" => "Jane" } }
      expected = { "userInfo" => { "firstName" => "Jane" } }

      expect(described_class.camelize_keys(input)).to eq(expected)
    end

    it "transforms hashes inside arrays" do
      input = { "items" => [{ "created_at" => "now" }] }
      expected = { "items" => [{ "createdAt" => "now" }] }

      expect(described_class.camelize_keys(input)).to eq(expected)
    end

    it "preserves $ref keys" do
      input = { "$ref" => "#/components/schemas/User" }

      expect(described_class.camelize_keys(input)).to eq(input)
    end

    it "handles non-hash, non-array values" do
      expect(described_class.camelize_keys("string")).to eq("string")
      expect(described_class.camelize_keys(42)).to eq(42)
    end
  end
end
