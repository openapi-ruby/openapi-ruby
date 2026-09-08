# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::ParameterNames do
  def param(attrs)
    attrs.transform_keys(&:to_s)
  end

  describe ".wire_name" do
    it "camelizes the declared name" do
      expect(described_class.wire_name(param(name: "page_size", in: "query"))).to eq("pageSize")
    end

    it "leaves single-word names alone" do
      expect(described_class.wire_name(param(name: "page", in: "query"))).to eq("page")
    end

    it "leaves header names alone" do
      expect(described_class.wire_name(param(name: "X-Request_Id", in: "header"))).to eq("X-Request_Id")
    end

    it "returns nil for a $ref parameter" do
      expect(described_class.wire_name(param("$ref": "#/components/parameters/Page"))).to be_nil
    end

    it "returns the declared name when camelize_keys is off" do
      OpenapiRuby.configuration.camelize_keys = false

      expect(described_class.wire_name(param(name: "page_size", in: "query"))).to eq("page_size")
    end
  end

  describe ".lookup_names" do
    it "returns both spellings" do
      expect(described_class.lookup_names(param(name: "page_size", in: "query"))).to eq(%w[page_size pageSize])
    end

    it "returns one entry when both spellings match" do
      expect(described_class.lookup_names(param(name: "page", in: "query"))).to eq(%w[page])
    end

    it "returns nothing for a $ref parameter" do
      expect(described_class.lookup_names(param("$ref": "#/components/parameters/Page"))).to eq([])
    end
  end

  describe ".parameters_for_document" do
    it "camelizes names and leaves the rest of the parameter untouched" do
      params = [param(name: "page_size", in: "query", schema: {"type" => "integer"})]

      expect(described_class.parameters_for_document(params)).to eq(
        [{"name" => "pageSize", "in" => "query", "schema" => {"type" => "integer"}}]
      )
    end

    it "passes $ref parameters through" do
      params = [param("$ref": "#/components/parameters/PageSize")]

      expect(described_class.parameters_for_document(params)).to eq(params)
    end

    it "does not mutate the declared parameters" do
      params = [param(name: "page_size", in: "query")]

      described_class.parameters_for_document(params)

      expect(params.first["name"]).to eq("page_size")
    end

    it "returns the parameters unchanged when camelize_keys is off" do
      OpenapiRuby.configuration.camelize_keys = false
      params = [param(name: "page_size", in: "query")]

      expect(described_class.parameters_for_document(params)).to eq(params)
    end
  end

  describe ".in_template" do
    it "camelizes template variables" do
      expect(described_class.in_template("/users/{user_id}/posts/{post_id}")).to eq("/users/{userId}/posts/{postId}")
    end

    it "leaves the static segments alone" do
      expect(described_class.in_template("/api/v1/user_settings")).to eq("/api/v1/user_settings")
    end

    it "returns the template unchanged when camelize_keys is off" do
      OpenapiRuby.configuration.camelize_keys = false

      expect(described_class.in_template("/users/{user_id}")).to eq("/users/{user_id}")
    end
  end

  describe ".rename_keys" do
    let(:parameters) { [param(name: "page_size", in: "query")] }

    it "renames declared keys to their wire name" do
      expect(described_class.rename_keys({page_size: 20}, parameters)).to eq("pageSize" => 20)
    end

    it "leaves undeclared keys alone" do
      expect(described_class.rename_keys({sort_by: "name"}, parameters)).to eq(sort_by: "name")
    end

    it "returns the values unchanged when camelize_keys is off" do
      OpenapiRuby.configuration.camelize_keys = false

      expect(described_class.rename_keys({page_size: 20}, parameters)).to eq(page_size: 20)
    end
  end
end
