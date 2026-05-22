# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::DSL::Context do
  describe "#to_openapi" do
    it "builds a path item with operations" do
      ctx = described_class.new("/users")
      ctx.get("List users") do
        response(200, "success") { schema(type: :array) }
      end

      result = ctx.to_openapi

      expect(result["get"]["summary"]).to eq("List users")
      expect(result["get"]["responses"]["200"]["description"]).to eq("success")
    end

    it "supports multiple HTTP methods" do
      ctx = described_class.new("/users")
      ctx.get("List") { response(200, "OK") }
      ctx.post("Create") { response(201, "Created") }

      result = ctx.to_openapi

      expect(result.keys).to include("get", "post")
    end

    it "outputs path-level parameters at path level" do
      ctx = described_class.new("/users/{id}")
      ctx.parameter(name: :id, in: :path, schema: {type: :integer})
      ctx.get("Get user") { response(200, "OK") }

      result = ctx.to_openapi

      expect(result["parameters"].length).to eq(1)
      expect(result["parameters"][0]["name"]).to eq("id")
      expect(result["parameters"][0]["required"]).to be true
      expect(result["get"]).not_to have_key("parameters")
    end

    it "stores schema_name" do
      ctx = described_class.new("/users", schema_name: :public_api)

      expect(ctx.schema_name).to eq(:public_api)
    end
  end

  describe "class ref auto-resolution" do
    before do
      OpenapiRuby::Components::Registry.instance.clear!
    end

    def create_component(name, type: :schemas, &block)
      klass = Class.new
      stub_const(name, klass)
      klass.include(OpenapiRuby::Components::Base)
      klass.component_type(type) unless type == :schemas
      klass.class_eval(&block) if block
      klass
    end

    it "resolves a component class in path-level parameter schema" do
      comp = create_component("Schemas::IdParam") do
        schema(type: :integer)
      end

      ctx = described_class.new("/users/{id}")
      ctx.parameter(name: :id, in: :path, schema: comp)

      result = ctx.to_openapi
      expect(result["parameters"][0]["schema"]).to eq(
        {"$ref" => "#/components/schemas/IdParam"}
      )
    end

    it "raises ArgumentError for non-component classes" do
      ctx = described_class.new("/users")

      expect { ctx.parameter(name: :id, in: :path, schema: String) }
        .to raise_error(ArgumentError, /not an OpenapiRuby component/)
    end
  end

  describe "HTTP methods" do
    OpenapiRuby::DSL::Context::HTTP_METHODS.each do |method|
      it "supports #{method}" do
        ctx = described_class.new("/test")
        ctx.send(method) { response(200, "OK") }

        expect(ctx.operations).to have_key(method.to_s)
      end
    end
  end
end
