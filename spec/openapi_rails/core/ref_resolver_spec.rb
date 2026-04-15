# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRails::Core::RefResolver do
  describe ".ref_path" do
    it "builds a JSON pointer" do
      expect(described_class.ref_path(:schemas, "User")).to eq("#/components/schemas/User")
    end
  end

  describe ".ref_object" do
    it "builds a $ref hash" do
      expect(described_class.ref_object(:schemas, "User")).to eq({ "$ref" => "#/components/schemas/User" })
    end
  end

  describe ".ref?" do
    it "returns true for $ref hashes" do
      expect(described_class.ref?({ "$ref" => "#/components/schemas/User" })).to be true
    end

    it "returns false for regular hashes" do
      expect(described_class.ref?({ "type" => "object" })).to be false
    end

    it "returns false for non-hashes" do
      expect(described_class.ref?("string")).to be false
    end
  end

  describe ".resolve" do
    it "resolves a $ref path in a document" do
      document = {
        "components" => {
          "schemas" => {
            "User" => { "type" => "object" }
          }
        }
      }

      result = described_class.resolve("#/components/schemas/User", document)

      expect(result).to eq({ "type" => "object" })
    end

    it "returns nil for unresolvable paths" do
      result = described_class.resolve("#/components/schemas/Missing", {})

      expect(result).to be_nil
    end
  end
end
