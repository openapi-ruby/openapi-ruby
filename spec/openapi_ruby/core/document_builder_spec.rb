# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::Core::DocumentBuilder do
  describe "#build" do
    it "creates a document with paths and components" do
      builder = described_class.new(info: {title: "API", version: "1.0"})

      builder.add_path("/users", {
        "get" => {
          "summary" => "List users",
          "responses" => {"200" => {"description" => "OK"}}
        }
      })

      builder.merge_components({
        "schemas" => {"User" => {"type" => "object"}}
      })

      doc = builder.build

      expect(doc.to_h["paths"]["/users"]["get"]["summary"]).to eq("List users")
      expect(doc.to_h["components"]["schemas"]["User"]).to eq({"type" => "object"})
    end

    it "deep merges multiple operations on same path" do
      builder = described_class.new(info: {title: "API", version: "1.0"})

      builder.add_path("/users", {"get" => {"summary" => "List"}})
      builder.add_path("/users", {"post" => {"summary" => "Create"}})

      doc = builder.build

      expect(doc.to_h["paths"]["/users"].keys).to contain_exactly("get", "post")
    end

    it "adds tags without duplicates" do
      builder = described_class.new(info: {title: "API", version: "1.0"})

      builder.add_tag({"name" => "Users", "description" => "User operations"})
      builder.add_tag({"name" => "Users", "description" => "Different desc"})
      builder.add_tag({"name" => "Posts", "description" => "Post operations"})

      doc = builder.build

      expect(doc.to_h["tags"].length).to eq(2)
      expect(doc.to_h["tags"].map { |t| t["name"] }).to contain_exactly("Users", "Posts")
    end

    it "sets security schemes" do
      builder = described_class.new(info: {title: "API", version: "1.0"})
      builder.add_security([{"bearerAuth" => []}])

      doc = builder.build

      expect(doc.to_h["security"]).to eq([{"bearerAuth" => []}])
    end
  end

  describe "#to_h" do
    it "returns a hash representation" do
      builder = described_class.new(info: {title: "API", version: "1.0"})
      result = builder.to_h

      expect(result).to be_a(Hash)
      expect(result["openapi"]).to eq("3.1.0")
    end
  end

  describe "auto validation error responses" do
    it "injects SchemaValidationError response component" do
      builder = described_class.new(info: {title: "API", version: "1.0"})
      builder.add_path("/users", {
        "get" => {
          "responses" => {"200" => {"description" => "OK"}}
        }
      })

      doc = builder.build

      expect(doc.to_h["components"]["responses"]["SchemaValidationError"]).to include(
        "description" => "Request validation failed"
      )
    end

    it "adds 400 ref to operations with parameters" do
      builder = described_class.new(info: {title: "API", version: "1.0"})
      builder.add_path("/users", {
        "get" => {
          "parameters" => [{"name" => "page", "in" => "query"}],
          "responses" => {"200" => {"description" => "OK"}}
        }
      })

      doc = builder.build

      expect(doc.to_h["paths"]["/users"]["get"]["responses"]["400"]).to eq(
        {"$ref" => "#/components/responses/SchemaValidationError"}
      )
    end

    it "skips 400 for operations without parameters or request body" do
      builder = described_class.new(info: {title: "API", version: "1.0"})
      builder.add_path("/health", {
        "get" => {
          "responses" => {"200" => {"description" => "OK"}}
        }
      })

      doc = builder.build

      expect(doc.to_h["paths"]["/health"]["get"]["responses"]["400"]).to be_nil
    end

    it "does not override existing 400 responses" do
      builder = described_class.new(info: {title: "API", version: "1.0"})
      builder.add_path("/users", {
        "get" => {
          "responses" => {
            "200" => {"description" => "OK"},
            "400" => {"description" => "Custom bad request"}
          }
        }
      })

      doc = builder.build

      expect(doc.to_h["paths"]["/users"]["get"]["responses"]["400"]).to eq(
        {"description" => "Custom bad request"}
      )
    end

    it "can be disabled" do
      OpenapiRuby.configuration.auto_validation_error_response = false

      builder = described_class.new(info: {title: "API", version: "1.0"})
      builder.add_path("/users", {
        "get" => {
          "responses" => {"200" => {"description" => "OK"}}
        }
      })

      doc = builder.build

      expect(doc.to_h["paths"]["/users"]["get"]["responses"]).not_to have_key("400")
      expect(doc.to_h).not_to have_key("components")
    ensure
      OpenapiRuby.configuration.auto_validation_error_response = true
    end

    it "uses custom validation_error_schema when configured" do
      custom_schema = {"$ref" => "#/components/schemas/StandardError"}
      OpenapiRuby.configuration.validation_error_schema = custom_schema

      builder = described_class.new(info: {title: "API", version: "1.0"})
      builder.add_path("/users", {
        "get" => {
          "responses" => {"200" => {"description" => "OK"}}
        }
      })

      doc = builder.build

      schema = doc.to_h.dig("components", "responses", "SchemaValidationError", "content", "application/json", "schema")
      expect(schema).to eq({"$ref" => "#/components/schemas/StandardError"})
    ensure
      OpenapiRuby.configuration.validation_error_schema = nil
    end
  end
end
