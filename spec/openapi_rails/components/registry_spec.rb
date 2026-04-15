# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRails::Components::Registry do
  subject(:registry) { described_class.instance }

  before { registry.clear! }

  def create_component(name, type: :schemas, hidden: false, scopes: [])
    klass = Class.new
    stub_const(name, klass)
    klass.include OpenapiRails::Components::Base
    klass.component_type(type) unless type == :schemas
    klass.schema_hidden(hidden) if hidden
    klass.component_scopes(*scopes) if scopes.any?
    klass.schema(type: :object)
    klass
  end

  describe "#register / #components_for" do
    it "registers and retrieves components by type" do
      comp = create_component("RegUser")

      expect(registry.components_for(:schemas)).to have_key("RegUser")
      expect(registry.components_for(:schemas)["RegUser"]).to eq(comp)
    end
  end

  describe "#unregister" do
    it "removes a component" do
      comp = create_component("RemovableComp")
      registry.unregister(comp)

      expect(registry.components_for(:schemas)).not_to have_key("RemovableComp")
    end
  end

  describe "#to_openapi_hash" do
    it "returns components grouped by type" do
      create_component("User1")
      create_component("BearerAuth1", type: :securitySchemes)

      result = registry.to_openapi_hash

      expect(result).to have_key("schemas")
      expect(result).to have_key("securitySchemes")
      expect(result["schemas"]).to have_key("User1")
      expect(result["securitySchemes"]).to have_key("BearerAuth1")
    end

    it "excludes hidden components" do
      create_component("VisibleComp1")
      create_component("HiddenComp1", hidden: true)

      result = registry.to_openapi_hash

      expect(result["schemas"]).to have_key("VisibleComp1")
      expect(result["schemas"]).not_to have_key("HiddenComp1")
    end

    it "filters by scope" do
      create_component("PublicComp", scopes: [:public])
      create_component("AdminComp", scopes: [:admin])
      create_component("SharedComp", scopes: [])

      result = registry.to_openapi_hash(scope: :public)

      expect(result["schemas"]).to have_key("PublicComp")
      expect(result["schemas"]).not_to have_key("AdminComp")
      expect(result["schemas"]).to have_key("SharedComp")
    end
  end

  describe "duplicate detection" do
    it "raises on duplicate names in the same type" do
      create_component("DupComp")

      expect {
        klass = Class.new
        stub_const("Other::DupComp", klass)
        klass.include OpenapiRails::Components::Base
      }.to raise_error(OpenapiRails::DuplicateComponentError, /DupComp/)
    end
  end
end
