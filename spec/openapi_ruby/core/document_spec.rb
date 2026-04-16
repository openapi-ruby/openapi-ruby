# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::Core::Document do
  describe "#initialize" do
    it "creates a minimal valid document" do
      doc = described_class.new(info: {title: "Test API", version: "1.0.0"})

      expect(doc.to_h).to include(
        "openapi" => "3.1.0",
        "info" => {"title" => "Test API", "version" => "1.0.0"},
        "paths" => {}
      )
    end

    it "provides default info values" do
      doc = described_class.new

      expect(doc.to_h["info"]["title"]).to eq("")
      expect(doc.to_h["info"]["version"]).to eq("0.0.0")
    end

    it "includes servers when provided" do
      doc = described_class.new(servers: [{url: "https://api.example.com"}])

      expect(doc.to_h["servers"]).to eq([{"url" => "https://api.example.com"}])
    end

    it "omits servers when empty" do
      doc = described_class.new(servers: [])

      expect(doc.to_h).not_to have_key("servers")
    end

    it "accepts a custom OpenAPI version >= 3.1" do
      doc = described_class.new(openapi_version: "3.1.1")

      expect(doc.to_h["openapi"]).to eq("3.1.1")
    end

    it "rejects OpenAPI versions below 3.1" do
      expect {
        described_class.new(openapi_version: "3.0.3")
      }.to raise_error(OpenapiRuby::ConfigurationError, /must be >= 3.1.0/)
    end

    it "defaults to 3.1.0" do
      doc = described_class.new

      expect(doc.to_h["openapi"]).to eq("3.1.0")
    end
  end

  describe "#add_path" do
    it "adds a path item" do
      doc = described_class.new(info: {title: "Test", version: "1.0"})
      doc.add_path("/users", {
        "get" => {
          "summary" => "List users",
          "responses" => {"200" => {"description" => "OK"}}
        }
      })

      expect(doc.to_h["paths"]["/users"]["get"]["summary"]).to eq("List users")
    end

    it "merges operations on the same path" do
      doc = described_class.new(info: {title: "Test", version: "1.0"})
      doc.add_path("/users", {"get" => {"summary" => "List"}})
      doc.add_path("/users", {"post" => {"summary" => "Create"}})

      expect(doc.to_h["paths"]["/users"].keys).to contain_exactly("get", "post")
    end
  end

  describe "#set_components" do
    it "sets components when non-empty" do
      doc = described_class.new(info: {title: "Test", version: "1.0"})
      doc.set_components({"schemas" => {"User" => {"type" => "object"}}})

      expect(doc.to_h["components"]["schemas"]["User"]).to eq({"type" => "object"})
    end

    it "does not set empty components" do
      doc = described_class.new(info: {title: "Test", version: "1.0"})
      doc.set_components({})

      expect(doc.to_h).not_to have_key("components")
    end
  end

  describe "#to_json" do
    it "returns valid JSON" do
      doc = described_class.new(info: {title: "Test", version: "1.0"})
      parsed = JSON.parse(doc.to_json)

      expect(parsed["openapi"]).to eq("3.1.0")
    end
  end

  describe "#to_yaml" do
    it "returns valid YAML" do
      doc = described_class.new(info: {title: "Test", version: "1.0"})
      parsed = YAML.safe_load(doc.to_yaml)

      expect(parsed["openapi"]).to eq("3.1.0")
    end
  end

  describe "#to_h sorting" do
    it "sorts paths alphabetically" do
      doc = described_class.new(info: {title: "Test", version: "1.0"})
      doc.add_path("/users", {"get" => {"responses" => {"200" => {"description" => "OK"}}}})
      doc.add_path("/accounts", {"get" => {"responses" => {"200" => {"description" => "OK"}}}})
      doc.add_path("/posts", {"get" => {"responses" => {"200" => {"description" => "OK"}}}})

      expect(doc.to_h["paths"].keys).to eq(["/accounts", "/posts", "/users"])
    end

    it "sorts component schemas alphabetically" do
      doc = described_class.new(info: {title: "Test", version: "1.0"})
      doc.set_components({"schemas" => {"User" => {"type" => "object"}, "Account" => {"type" => "object"}, "Post" => {"type" => "object"}}})

      expect(doc.to_h["components"]["schemas"].keys).to eq(["Account", "Post", "User"])
    end

    it "sorts tags alphabetically" do
      doc = described_class.new(info: {title: "Test", version: "1.0"})
      doc.set_tags([{"name" => "Users"}, {"name" => "Accounts"}, {"name" => "Posts"}])

      expect(doc.to_h["tags"].map { |t| t["name"] }).to eq(["Accounts", "Posts", "Users"])
    end
  end

  describe "#validate" do
    it "returns no errors for a valid document" do
      doc = described_class.new(info: {title: "Test API", version: "1.0.0"})
      doc.add_path("/health", {
        "get" => {
          "responses" => {"200" => {"description" => "OK"}}
        }
      })

      expect(doc.validate).to be_empty
    end
  end
end
