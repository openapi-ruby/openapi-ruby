# frozen_string_literal: true

# Validates that:
# 1. The static openapi/public_api.yaml in the dummy app is valid OpenAPI 3.1
# 2. The generation pipeline produces output matching that static spec
# 3. All endpoints and components are present and correctly structured

require "spec_helper"
require_relative "../support/rails_app"
require "tmpdir"
require "securerandom"

RSpec.describe "OpenAPI spec generation" do
  let(:static_spec_path) { File.expand_path("../dummy/openapi/public_api.yaml", __dir__) }
  let(:static_spec) { YAML.safe_load_file(static_spec_path) }

  describe "static spec file" do
    it "is valid OpenAPI 3.1" do
      schemer = JSONSchemer.openapi(static_spec)
      errors = schemer.validate.to_a

      expect(errors).to be_empty,
        "openapi/public_api.yaml is not valid OpenAPI 3.1:\n#{errors.map { |e| e["error"] }.join("\n")}"
    end

    it "documents all User endpoints" do
      paths = static_spec["paths"]

      expect(paths).to have_key("/api/v1/users")
      expect(paths["/api/v1/users"]).to have_key("get")
      expect(paths["/api/v1/users"]).to have_key("post")

      expect(paths).to have_key("/api/v1/users/{id}")
      expect(paths["/api/v1/users/{id}"]).to have_key("get")
      expect(paths["/api/v1/users/{id}"]).to have_key("patch")
      expect(paths["/api/v1/users/{id}"]).to have_key("delete")
    end

    it "documents all Post endpoints" do
      paths = static_spec["paths"]

      expect(paths).to have_key("/api/v1/posts")
      expect(paths["/api/v1/posts"]).to have_key("get")
      expect(paths["/api/v1/posts"]).to have_key("post")

      expect(paths).to have_key("/api/v1/posts/{id}")
      expect(paths["/api/v1/posts/{id}"]).to have_key("get")
      expect(paths["/api/v1/posts/{id}"]).to have_key("delete")
    end

    it "includes all schema components" do
      schemas = static_spec.dig("components", "schemas")

      %w[User UserInput Post PostInput ErrorResponse ValidationErrors].each do |name|
        expect(schemas).to have_key(name), "Missing component schema: #{name}"
      end
    end

    it "has correct schema structure for User" do
      user = static_spec.dig("components", "schemas", "User")

      expect(user["type"]).to eq("object")
      expect(user["required"]).to contain_exactly("id", "name", "email")
      expect(user["properties"].keys).to contain_exactly("id", "name", "email", "createdAt", "updatedAt")
    end

    it "has correct schema structure for Post" do
      post = static_spec.dig("components", "schemas", "Post")

      expect(post["type"]).to eq("object")
      expect(post["required"]).to contain_exactly("id", "title", "user_id")
      expect(post["properties"].keys).to contain_exactly("id", "title", "body", "user_id", "createdAt", "updatedAt")
    end

    it "uses $ref for response schemas" do
      create_user = static_spec.dig("paths", "/api/v1/users", "post")
      schema_201 = create_user.dig("responses", "201", "content", "application/json", "schema")
      schema_422 = create_user.dig("responses", "422", "content", "application/json", "schema")

      expect(schema_201).to eq({"$ref" => "#/components/schemas/User"})
      expect(schema_422).to eq({"$ref" => "#/components/schemas/ValidationErrors"})
    end

    it "uses requestBody for POST/PATCH operations" do
      create_user = static_spec.dig("paths", "/api/v1/users", "post")
      expect(create_user["requestBody"]["required"]).to be true
      expect(create_user.dig("requestBody", "content", "application/json", "schema", "$ref"))
        .to eq("#/components/schemas/UserInput")

      create_post = static_spec.dig("paths", "/api/v1/posts", "post")
      expect(create_post.dig("requestBody", "content", "application/json", "schema", "$ref"))
        .to eq("#/components/schemas/PostInput")
    end
  end

  describe "generation pipeline" do
    let(:output_dir) { File.join(Dir.tmpdir, "openapi_ruby_gen_#{SecureRandom.hex(4)}") }

    before do
      OpenapiRuby::DSL::MetadataStore.clear!
      OpenapiRuby::Components::Registry.instance.clear!
      Dir[File.expand_path("../dummy/app/api_components/**/*.rb", __dir__)].each { |f| load f }
    end

    after { FileUtils.rm_rf(output_dir) }

    it "produces a valid OpenAPI 3.1 document from DSL definitions and components" do
      # Register the same endpoints the dummy app's tests define
      register_users_endpoints
      register_posts_endpoints

      # Generate
      OpenapiRuby.configuration.schema_output_dir = output_dir
      config = {info: {title: "Dummy API", version: "1.0.0"}, servers: [{url: "/"}]}
      writer = OpenapiRuby::Generator::SchemaWriter.new(:public_api, config)
      path = writer.write!

      generated = YAML.safe_load_file(path)

      # Valid OpenAPI 3.1
      schemer = JSONSchemer.openapi(generated)
      errors = schemer.validate.to_a
      expect(errors).to be_empty,
        "Generated spec is not valid OpenAPI 3.1:\n#{errors.map { |e| e["error"] }.join("\n")}"

      # Same paths as static spec
      expect(generated["paths"].keys.sort).to eq(static_spec["paths"].keys.sort)

      # Same components as static spec
      expect(generated.dig("components", "schemas").keys.sort)
        .to eq(static_spec.dig("components", "schemas").keys.sort)
    end
  end

  private

  def register_users_endpoints
    users_ctx = OpenapiRuby::DSL::Context.new("/api/v1/users", schema_name: :public_api)
    users_ctx.get("List users") do
      tags "Users"
      operationId "listUsers"
      produces "application/json"
      response(200, "returns all users") do
        schema type: :array, items: {"$ref" => "#/components/schemas/User"}
      end
    end
    users_ctx.post("Create a user") do
      tags "Users"
      operationId "createUser"
      consumes "application/json"
      produces "application/json"
      request_body(required: true, content: {
        "application/json" => {schema: {"$ref" => "#/components/schemas/UserInput"}}
      })
      response(201, "user created") { schema "$ref" => "#/components/schemas/User" }
      response(422, "validation errors") { schema "$ref" => "#/components/schemas/ValidationErrors" }
    end
    OpenapiRuby::DSL::MetadataStore.register(users_ctx)

    user_ctx = OpenapiRuby::DSL::Context.new("/api/v1/users/{id}", schema_name: :public_api)
    user_ctx.parameter(name: :id, in: :path, schema: {type: :integer})
    user_ctx.get("Get a user") do
      tags "Users"
      operationId "getUser"
      produces "application/json"
      response(200, "user found") { schema "$ref" => "#/components/schemas/User" }
      response(404, "user not found") { schema "$ref" => "#/components/schemas/ErrorResponse" }
    end
    user_ctx.patch("Update a user") do
      tags "Users"
      operationId "updateUser"
      consumes "application/json"
      produces "application/json"
      request_body(required: false, content: {
        "application/json" => {schema: {"$ref" => "#/components/schemas/UserInput"}}
      })
      response(200, "user updated") { schema "$ref" => "#/components/schemas/User" }
      response(404, "user not found") { schema "$ref" => "#/components/schemas/ErrorResponse" }
    end
    user_ctx.delete("Delete a user") do
      tags "Users"
      operationId "deleteUser"
      response(204, "user deleted")
      response(404, "user not found") { schema "$ref" => "#/components/schemas/ErrorResponse" }
    end
    OpenapiRuby::DSL::MetadataStore.register(user_ctx)
  end

  def register_posts_endpoints
    posts_ctx = OpenapiRuby::DSL::Context.new("/api/v1/posts", schema_name: :public_api)
    posts_ctx.get("List posts") do
      tags "Posts"
      operationId "listPosts"
      produces "application/json"
      parameter name: :user_id, in: :query, schema: {type: :integer}, required: false
      response(200, "returns posts") do
        schema type: :array, items: {"$ref" => "#/components/schemas/Post"}
      end
    end
    posts_ctx.post("Create a post") do
      tags "Posts"
      operationId "createPost"
      consumes "application/json"
      produces "application/json"
      request_body(required: true, content: {
        "application/json" => {schema: {"$ref" => "#/components/schemas/PostInput"}}
      })
      response(201, "post created") { schema "$ref" => "#/components/schemas/Post" }
      response(422, "validation errors") { schema "$ref" => "#/components/schemas/ValidationErrors" }
    end
    OpenapiRuby::DSL::MetadataStore.register(posts_ctx)

    post_ctx = OpenapiRuby::DSL::Context.new("/api/v1/posts/{id}", schema_name: :public_api)
    post_ctx.parameter(name: :id, in: :path, schema: {type: :integer})
    post_ctx.get("Get a post") do
      tags "Posts"
      operationId "getPost"
      produces "application/json"
      response(200, "post found") { schema "$ref" => "#/components/schemas/Post" }
      response(404, "post not found") { schema "$ref" => "#/components/schemas/ErrorResponse" }
    end
    post_ctx.delete("Delete a post") do
      tags "Posts"
      operationId "deletePost"
      response(204, "post deleted")
      response(404, "post not found") { schema "$ref" => "#/components/schemas/ErrorResponse" }
    end
    OpenapiRuby::DSL::MetadataStore.register(post_ctx)
  end
end
