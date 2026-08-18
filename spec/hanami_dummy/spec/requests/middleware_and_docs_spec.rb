# frozen_string_literal: true

require "spec_helper"
require "rack/test"

# Covers the two things the Hanami host wires up by hand: the validation
# middleware installed from config/app.rb, and the docs endpoints mounted in
# config/routes.rb.
RSpec.describe "openapi_ruby Hanami integration" do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  describe "validation middleware" do
    it "is installed in the app's middleware stack" do
      installed = Hanami.app.config.middleware.stack.values.flatten(1).map(&:first)

      expect(installed).to include(
        OpenapiRuby::Middleware::RequestValidation,
        OpenapiRuby::Middleware::ResponseValidation
      )
    end

    it "rejects a request that does not match the declared operation" do
      post "/api/v1/posts", {title: 42}.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)["error"]).to eq("Request validation failed")
    end

    it "rejects a request missing a required property" do
      post "/api/v1/posts", {body: "no title"}.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(400)
    end

    it "lets a valid request through" do
      post "/api/v1/posts", {title: "Valid"}.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(201)
    end

    # The schema's :prefix keeps the middleware off everything outside the API,
    # including the docs endpoints mounted below.
    it "leaves unprefixed paths alone" do
      get "/api-docs/schemas"

      expect(last_response.status).to eq(200)
    end
  end

  describe "mounted docs endpoints" do
    it "lists the configured schemas" do
      get "/api-docs/schemas"

      expect(JSON.parse(last_response.body)).to eq("schemas" => ["public_api"])
    end

    it "serves the generated document" do
      get "/api-docs/schemas/public_api.yaml"

      expect(last_response.status).to eq(200)
      expect(YAML.safe_load(last_response.body)["info"]["title"]).to eq("Hanami Dummy API")
    end

    it "serves Swagger UI pointing at the mounted schema path" do
      get "/api-docs"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('url: "/api-docs/schemas/public_api.yaml"')
    end

    it "404s for an unknown schema" do
      get "/api-docs/schemas/nope.yaml"

      expect(last_response.status).to eq(404)
    end
  end
end
