# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRails::Core::DocumentBuilder do
  describe "#build" do
    it "creates a document with paths and components" do
      builder = described_class.new(info: { title: "API", version: "1.0" })

      builder.add_path("/users", {
        "get" => {
          "summary" => "List users",
          "responses" => { "200" => { "description" => "OK" } }
        }
      })

      builder.merge_components({
        "schemas" => { "User" => { "type" => "object" } }
      })

      doc = builder.build

      expect(doc.to_h["paths"]["/users"]["get"]["summary"]).to eq("List users")
      expect(doc.to_h["components"]["schemas"]["User"]).to eq({ "type" => "object" })
    end

    it "deep merges multiple operations on same path" do
      builder = described_class.new(info: { title: "API", version: "1.0" })

      builder.add_path("/users", { "get" => { "summary" => "List" } })
      builder.add_path("/users", { "post" => { "summary" => "Create" } })

      doc = builder.build

      expect(doc.to_h["paths"]["/users"].keys).to contain_exactly("get", "post")
    end

    it "adds tags without duplicates" do
      builder = described_class.new(info: { title: "API", version: "1.0" })

      builder.add_tag({ "name" => "Users", "description" => "User operations" })
      builder.add_tag({ "name" => "Users", "description" => "Different desc" })
      builder.add_tag({ "name" => "Posts", "description" => "Post operations" })

      doc = builder.build

      expect(doc.to_h["tags"].length).to eq(2)
      expect(doc.to_h["tags"].map { |t| t["name"] }).to contain_exactly("Users", "Posts")
    end

    it "sets security schemes" do
      builder = described_class.new(info: { title: "API", version: "1.0" })
      builder.add_security([{ "bearerAuth" => [] }])

      doc = builder.build

      expect(doc.to_h["security"]).to eq([{ "bearerAuth" => [] }])
    end
  end

  describe "#to_h" do
    it "returns a hash representation" do
      builder = described_class.new(info: { title: "API", version: "1.0" })
      result = builder.to_h

      expect(result).to be_a(Hash)
      expect(result["openapi"]).to eq("3.1.0")
    end
  end
end
