# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::DSL::OperationContext do
  describe "#to_openapi" do
    it "builds a basic operation" do
      op = described_class.new(:get, "List users")
      op.response(200, "success") { schema(type: :array) }

      result = op.to_openapi

      expect(result["summary"]).to eq("List users")
      expect(result["responses"]["200"]["description"]).to eq("success")
    end

    it "includes tags" do
      op = described_class.new(:get)
      op.tags("Users", "Public")

      result = op.to_openapi

      expect(result["tags"]).to eq(%w[Users Public])
    end

    it "includes operationId" do
      op = described_class.new(:get)
      op.operationId("listUsers")

      expect(op.to_openapi["operationId"]).to eq("listUsers")
    end

    it "includes description" do
      op = described_class.new(:get)
      op.description("Returns all users")

      expect(op.to_openapi["description"]).to eq("Returns all users")
    end

    it "marks as deprecated" do
      op = described_class.new(:get)
      op.deprecated(true)

      expect(op.to_openapi["deprecated"]).to be true
    end

    it "includes parameters" do
      op = described_class.new(:get)
      op.parameter(name: :page, in: :query, schema: {type: :integer})

      params = op.to_openapi["parameters"]

      expect(params.length).to eq(1)
      expect(params[0]["name"]).to eq("page")
      expect(params[0]["in"]).to eq("query")
    end

    it "auto-requires path parameters" do
      op = described_class.new(:get)
      op.parameter(name: :id, in: :path, schema: {type: :integer})

      params = op.to_openapi["parameters"]

      expect(params[0]["required"]).to be true
    end

    it "includes request body" do
      op = described_class.new(:post)
      op.request_body(
        required: true,
        content: {
          "application/json" => {
            schema: {"$ref" => "#/components/schemas/UserInput"}
          }
        }
      )

      result = op.to_openapi

      expect(result["requestBody"]["required"]).to be(true)
      expect(result["requestBody"]["content"]["application/json"]["schema"]["$ref"])
        .to eq("#/components/schemas/UserInput")
    end

    it "includes security" do
      op = described_class.new(:get)
      op.security([{bearerAuth: []}])

      expect(op.to_openapi["security"]).to eq([{"bearerAuth" => []}])
    end

    it "includes request body examples" do
      op = described_class.new(:post)
      op.request_body(
        required: true,
        content: {
          "application/json" => {
            schema: {type: :object}
          }
        }
      )
      op.request_body_example(value: {name: "Jane"}, name: "basic", summary: "Basic example")

      result = op.to_openapi
      examples = result["requestBody"]["content"]["application/json"]["examples"]

      expect(examples["basic"]["value"]).to eq({name: "Jane"})
      expect(examples["basic"]["summary"]).to eq("Basic example")
    end
  end

  describe "class ref auto-resolution" do
    before do
      OpenapiRuby::Components::Registry.instance.clear!
    end

    def create_component(name, &block)
      klass = Class.new
      stub_const(name, klass)
      klass.include(OpenapiRuby::Components::Base)
      klass.class_eval(&block) if block
      klass
    end

    it "resolves a component class in request_body content schema" do
      comp = create_component("Schemas::UserInput") do
        schema(type: :object)
      end

      op = described_class.new(:post)
      op.request_body(
        required: true,
        content: {
          "application/json" => {schema: comp}
        }
      )

      result = op.to_openapi
      expect(result["requestBody"]["content"]["application/json"]["schema"]).to eq(
        {"$ref" => "#/components/schemas/UserInput"}
      )
    end

    it "resolves a component class in request_body shorthand" do
      comp = create_component("Schemas::PostInput") do
        schema(type: :object)
      end

      op = described_class.new(:post)
      op.request_body(required: true, schema: comp)

      result = op.to_openapi
      expect(result["requestBody"]["content"]["application/json"]["schema"]).to eq(
        {"$ref" => "#/components/schemas/PostInput"}
      )
    end

    it "resolves a component class in operation-level parameter schema" do
      comp = create_component("Schemas::FilterParam") do
        schema(type: :string)
      end

      op = described_class.new(:get)
      op.parameter(name: :filter, in: :query, schema: comp)

      params = op.to_openapi["parameters"]
      expect(params[0]["schema"]).to eq(
        {"$ref" => "#/components/schemas/FilterParam"}
      )
    end

    it "resolves a component class in response schema via block" do
      comp = create_component("Schemas::User") do
        schema(type: :object)
      end

      op = described_class.new(:get)
      op.response(200, "success") { schema(comp) }

      result = op.to_openapi
      expect(result["responses"]["200"]["content"]["application/json"]["schema"]).to eq(
        {"$ref" => "#/components/schemas/User"}
      )
    end

    it "resolves a component class nested inside array items in response" do
      comp = create_component("Schemas::Item") do
        schema(type: :object)
      end

      op = described_class.new(:get)
      op.response(200, "success") { schema(type: :array, items: comp) }

      result = op.to_openapi
      expect(result["responses"]["200"]["content"]["application/json"]["schema"]["items"]).to eq(
        {"$ref" => "#/components/schemas/Item"}
      )
    end
  end

  describe "#response" do
    it "creates and stores response contexts" do
      op = described_class.new(:get)
      ctx = op.response(200, "OK")

      expect(ctx).to be_a(OpenapiRuby::DSL::ResponseContext)
      expect(op.responses).to have_key("200")
    end

    it "passes produces to response" do
      op = described_class.new(:get)
      op.produces("text/csv")
      op.response(200, "OK") { schema(type: :string) }

      result = op.to_openapi

      expect(result["responses"]["200"]["content"]).to have_key("text/csv")
    end
  end
end
