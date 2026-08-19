# frozen_string_literal: true

require "spec_helper"
require "rack/builder"

# Covers what a Rack host wires by hand: the validation middleware installed
# onto Sinatra's class-level stack, and the docs endpoints mapped in config.ru.
RSpec.describe "openapi_ruby on Sinatra" do
  include Rack::Test::Methods

  describe "validation middleware" do
    let(:app) { App }

    it "is installed on the Sinatra middleware stack" do
      installed = App.middleware.map(&:first)

      expect(installed).to include(
        OpenapiRuby::Middleware::RequestValidation,
        OpenapiRuby::Middleware::ResponseValidation
      )
    end

    it "rejects a body whose property has the wrong type" do
      post "/api/v1/posts", {title: 42}.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)["error"]).to eq("Request validation failed")
    end

    it "rejects a body missing a required property" do
      post "/api/v1/posts", {body: "no title"}.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(400)
    end

    it "lets a valid body through" do
      post "/api/v1/posts", {title: "Valid"}.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(201)
    end
  end

  # Exercised through the real config.ru rather than a hand-built stack, so the
  # mount the README documents is the one under test.
  describe "the documented rack-up stack" do
    let(:app) do
      built = Rack::Builder.parse_file(File.expand_path("../../config.ru", __dir__))
      # Rack 2 hands back [app, options]; Rack 3 hands back the app.
      built.is_a?(Array) ? built.first : built
    end

    it "serves the API" do
      PostStore.create(title: "Mounted")

      get "/api/v1/posts"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body).first["title"]).to eq("Mounted")
    end

    it "lists the schemas" do
      get "/api-docs/schemas"

      expect(JSON.parse(last_response.body)).to eq("schemas" => ["public_api"])
    end

    it "serves the generated document" do
      get "/api-docs/schemas/public_api.yaml"

      expect(last_response.status).to eq(200)
      expect(YAML.safe_load(last_response.body)["info"]["title"]).to eq("Sinatra Dummy API")
    end

    it "serves Swagger UI pointing at the mounted schema path" do
      get "/api-docs"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('url: "/api-docs/schemas/public_api.yaml"')
    end

    it "answers HEAD without a body" do
      head "/api-docs/schemas/public_api.yaml"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to be_empty
    end
  end
end
