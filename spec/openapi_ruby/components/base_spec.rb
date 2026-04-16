# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::Components::Base do
  before do
    OpenapiRuby::Components::Registry.instance.clear!
  end

  def create_component(name, parent: nil, &block)
    klass = if parent
      Class.new(parent)
    else
      Class.new
    end
    stub_const(name, klass)
    klass.include(OpenapiRuby::Components::Base) unless parent
    klass.class_eval(&block) if block
    klass
  end

  describe ".schema" do
    it "defines a schema" do
      comp = create_component("TestSchema") do
        schema(type: :object, properties: {name: {type: :string}})
      end

      expect(comp.schema).to eq({"type" => "object", "properties" => {"name" => {"type" => "string"}}})
    end

    it "deep merges with existing schema" do
      comp = create_component("MergeSchema") do
        schema(type: :object, properties: {id: {type: :integer}})
        schema(properties: {name: {type: :string}})
      end

      expect(comp.schema["properties"].keys).to contain_exactly("id", "name")
    end
  end

  describe "inheritance" do
    it "inherits schema from parent" do
      parent = create_component("ParentSchema") do
        schema(type: :object, properties: {id: {type: :integer}})
      end

      child = create_component("ChildSchema", parent: parent) do
        schema(properties: {name: {type: :string}})
      end

      expect(child.schema["properties"].keys).to contain_exactly("id", "name")
      expect(child.schema["type"]).to eq("object")
    end

    it "does not modify parent schema" do
      parent = create_component("ImmutableParent") do
        schema(type: :object, properties: {id: {type: :integer}})
      end

      create_component("ImmutableChild", parent: parent) do
        schema(properties: {name: {type: :string}})
      end

      expect(parent.schema["properties"].keys).to eq(["id"])
    end
  end

  describe ".schema_hidden" do
    it "marks a component as hidden" do
      comp = create_component("HiddenSchema") do
        schema_hidden true
        schema(type: :object)
      end

      expect(comp._schema_hidden).to be true
    end

    it "defaults to not hidden" do
      comp = create_component("VisibleSchema") do
        schema(type: :object)
      end

      expect(comp._schema_hidden).to be false
    end
  end

  describe ".component_type" do
    it "defaults to :schemas" do
      comp = create_component("DefaultType") do
        schema(type: :object)
      end

      expect(comp._component_type).to eq(:schemas)
    end

    it "can be changed" do
      comp = create_component("SecurityComp") do
        component_type :security_schemes
        schema(type: :http, scheme: :bearer)
      end

      expect(comp._component_type).to eq(:security_schemes)
    end
  end

  describe ".component_name" do
    it "returns the demodulized class name" do
      comp = create_component("Schemas::UserProfile") do
        schema(type: :object)
      end

      expect(comp.component_name).to eq("UserProfile")
    end
  end

  describe ".to_openapi" do
    it "injects title for schema components" do
      comp = create_component("TitledSchema") do
        schema(type: :object)
      end

      expect(comp.to_openapi["title"]).to eq("TitledSchema")
    end

    it "does not override existing title" do
      comp = create_component("CustomTitle") do
        schema(type: :object, title: "My Custom Title")
      end

      expect(comp.to_openapi["title"]).to eq("My Custom Title")
    end

    it "camelizes keys by default" do
      comp = create_component("CamelSchema") do
        schema(type: :object, properties: {first_name: {type: :string}})
      end

      openapi = comp.to_openapi
      expect(openapi["properties"]).to have_key("firstName")
    end

    it "skips key transformation when configured" do
      comp = create_component("SkipTransform") do
        skip_key_transformation true
        schema(type: :object, properties: {first_name: {type: :string}})
      end

      openapi = comp.to_openapi
      expect(openapi["properties"]).to have_key("first_name")
    end

    it "skips key transformation when globally disabled" do
      OpenapiRuby.configuration.camelize_keys = false

      comp = create_component("GlobalSkip") do
        schema(type: :object, properties: {first_name: {type: :string}})
      end

      openapi = comp.to_openapi
      expect(openapi["properties"]).to have_key("first_name")
    end
  end

  describe ".component_scopes" do
    it "sets scopes for the component" do
      comp = create_component("ScopedSchema") do
        component_scopes :public, :admin
        schema(type: :object)
      end

      expect(comp._component_scopes).to eq(%i[public admin])
    end
  end

  describe ".shared_component" do
    it "marks a component as shared (empty scopes)" do
      comp = create_component("SharedSchema") do
        shared_component
        schema(type: :object)
      end

      expect(comp._component_scopes).to eq([])
    end
  end

  describe ".registry_key" do
    it "returns component_name when no scopes" do
      comp = create_component("Schemas::UnscoppedComp") do
        schema(type: :object)
      end

      expect(comp.registry_key).to eq("UnscoppedComp")
    end

    it "includes scopes when present" do
      comp = create_component("Schemas::ScopedComp") do
        component_scopes :admin
        schema(type: :object)
      end

      expect(comp.registry_key).to eq("admin:ScopedComp")
    end
  end
end
