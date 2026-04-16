# frozen_string_literal: true

require "spec_helper"
require "rack"
require "rack/test"

RSpec.describe OpenapiRuby::Middleware::RequestValidation do
  include Rack::Test::Methods

  let(:inner_app) { ->(_env) { [200, {"content-type" => "application/json"}, ['{"ok":true}']] } }
  let(:document) do
    {
      "openapi" => "3.1.0",
      "info" => {"title" => "Test", "version" => "1.0"},
      "paths" => {
        "/users" => {
          "get" => {
            "parameters" => [
              {"name" => "page", "in" => "query", "required" => true, "schema" => {"type" => "integer"}},
              {"name" => "per_page", "in" => "query", "required" => false, "schema" => {"type" => "integer"}}
            ],
            "responses" => {"200" => {"description" => "OK"}}
          },
          "post" => {
            "requestBody" => {
              "required" => true,
              "content" => {
                "application/json" => {
                  "schema" => {
                    "type" => "object",
                    "required" => ["name", "email"],
                    "properties" => {
                      "name" => {"type" => "string", "minLength" => 1},
                      "email" => {"type" => "string"}
                    }
                  }
                }
              }
            },
            "responses" => {"201" => {"description" => "Created"}}
          }
        },
        "/users/{id}" => {
          "get" => {
            "parameters" => [
              {"name" => "id", "in" => "path", "required" => true, "schema" => {"type" => "integer"}}
            ],
            "responses" => {"200" => {"description" => "OK"}}
          }
        }
      }
    }
  end

  let(:resolver) { OpenapiRuby::Middleware::SchemaResolver.new(document: document) }

  let(:app) do
    described_class.new(inner_app, schema_resolver: resolver, mode: :enabled, strict: false)
  end

  describe "parameter presence validation" do
    it "passes valid requests" do
      get "/users?page=1"
      expect(last_response.status).to eq(200)
    end

    it "rejects requests missing required query params" do
      get "/users"
      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body["details"]).to include(/Missing required query parameter: page/)
    end

    it "allows missing optional params" do
      get "/users?page=1"
      expect(last_response.status).to eq(200)
    end
  end

  describe "parameter type validation" do
    it "rejects query params with wrong type" do
      get "/users?page=notanumber"
      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body["details"].first).to match(/Invalid.*page/i)
    end

    it "accepts valid integer params as strings (coerced)" do
      get "/users?page=5"
      expect(last_response.status).to eq(200)
    end
  end

  describe "request body validation" do
    it "rejects missing required request body" do
      post "/users", "", {"CONTENT_TYPE" => "application/json"}
      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body["details"]).to include(/Request body is required/)
    end

    it "rejects request body missing required fields" do
      post "/users", '{"name":"Jane"}', {"CONTENT_TYPE" => "application/json"}
      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body["details"].first).to match(/email|required/i)
    end

    it "rejects request body with wrong field types" do
      post "/users", '{"name":123,"email":"test@example.com"}', {"CONTENT_TYPE" => "application/json"}
      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body["details"].first).to match(/name|type/i)
    end

    it "rejects request body violating constraints" do
      post "/users", '{"name":"","email":"test@example.com"}', {"CONTENT_TYPE" => "application/json"}
      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body["details"].first).to match(/name|minLength/i)
    end

    it "passes valid request body" do
      post "/users", '{"name":"Jane","email":"jane@example.com"}', {"CONTENT_TYPE" => "application/json"}
      expect(last_response.status).to eq(200)
    end

    it "rejects unsupported content type" do
      post "/users", "name=Jane", {"CONTENT_TYPE" => "text/plain"}
      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body["details"]).to include(/Unsupported content type/)
    end
  end

  describe "path parameter validation" do
    it "validates path parameters" do
      get "/users/42"
      expect(last_response.status).to eq(200)
    end
  end

  describe "undocumented paths" do
    it "passes through in non-strict mode" do
      get "/unknown"
      expect(last_response.status).to eq(200)
    end

    context "with strict mode" do
      let(:app) do
        described_class.new(inner_app, schema_resolver: resolver, mode: :enabled, strict: true)
      end

      it "returns 404" do
        get "/unknown"
        expect(last_response.status).to eq(404)
      end
    end
  end

  describe "warn_only mode" do
    let(:app) do
      described_class.new(inner_app, schema_resolver: resolver, mode: :warn_only)
    end

    it "passes invalid requests through with warnings" do
      expect { get "/users" }.to output(/Request validation warnings/).to_stderr
      expect(last_response.status).to eq(200)
    end
  end

  describe "disabled mode" do
    let(:app) do
      described_class.new(inner_app, schema_resolver: resolver, mode: :disabled)
    end

    it "skips all validation" do
      get "/users"
      expect(last_response.status).to eq(200)
    end
  end

  describe "prefix filtering" do
    let(:app) do
      described_class.new(inner_app, schema_resolver: resolver, mode: :enabled, prefix: "/api/v1")
    end

    let(:document) do
      {
        "openapi" => "3.1.0",
        "info" => {"title" => "Test", "version" => "1.0"},
        "paths" => {
          "/users" => {
            "get" => {
              "parameters" => [
                {"name" => "page", "in" => "query", "required" => true, "schema" => {"type" => "integer"}}
              ],
              "responses" => {"200" => {"description" => "OK"}}
            }
          }
        }
      }
    end

    it "skips validation for requests not matching prefix" do
      get "/other/path"
      expect(last_response.status).to eq(200)
    end

    it "validates requests matching prefix with prefix stripped" do
      get "/api/v1/users?page=1"
      expect(last_response.status).to eq(200)
    end

    it "rejects invalid requests matching prefix" do
      get "/api/v1/users"
      expect(last_response.status).to eq(400)
    end
  end

  describe "form data parsing" do
    let(:document) do
      {
        "openapi" => "3.1.0",
        "info" => {"title" => "Test", "version" => "1.0"},
        "paths" => {
          "/upload" => {
            "post" => {
              "requestBody" => {
                "required" => true,
                "content" => {
                  "application/x-www-form-urlencoded" => {
                    "schema" => {
                      "type" => "object",
                      "required" => ["name"],
                      "properties" => {
                        "name" => {"type" => "string"}
                      }
                    }
                  }
                }
              },
              "responses" => {"200" => {"description" => "OK"}}
            }
          }
        }
      }
    end

    it "parses url-encoded form data" do
      post "/upload", "name=Jane", {"CONTENT_TYPE" => "application/x-www-form-urlencoded"}
      expect(last_response.status).to eq(200)
    end
  end
end
