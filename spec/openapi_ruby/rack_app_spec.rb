# frozen_string_literal: true

require "spec_helper"
require "rack/test"
require "tmpdir"

RSpec.describe OpenapiRuby::RackApp do
  include Rack::Test::Methods

  let(:app) { described_class }
  let(:root) { Pathname.new(Dir.mktmpdir) }

  before do
    allow(OpenapiRuby).to receive(:app_root).and_return(root.to_s)
    FileUtils.mkdir_p(root.join("openapi"))
    File.write(root.join("openapi", "public_api.yaml"), {"openapi" => "3.1.0", "paths" => {}}.to_yaml)

    OpenapiRuby.configure do |config|
      config.schemas = {public_api: {info: {title: "Public API", version: "1.0"}}}
    end
  end

  after { FileUtils.remove_entry(root) }

  describe "GET /schemas" do
    it "lists the configured schemas" do
      get "/schemas"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq("schemas" => ["public_api"])
    end
  end

  describe "GET /schemas/:name" do
    it "serves the generated document" do
      get "/schemas/public_api.yaml"

      expect(last_response.status).to eq(200)
      expect(last_response.headers["content-type"]).to eq("application/x-yaml")
      expect(YAML.safe_load(last_response.body)).to include("openapi" => "3.1.0")
    end

    it "serves the document without an extension" do
      get "/schemas/public_api"

      expect(last_response.status).to eq(200)
    end

    it "applies the configured openapi_filter" do
      OpenapiRuby.configuration.schemas[:public_api][:openapi_filter] =
        ->(doc, request) { doc["servers"] = [{"url" => "https://#{request.host}"}] }

      get "/schemas/public_api.yaml"

      expect(YAML.safe_load(last_response.body)["servers"]).to eq([{"url" => "https://example.org"}])
    end

    it "404s for an unconfigured schema" do
      get "/schemas/unknown.yaml"

      expect(last_response.status).to eq(404)
    end

    it "404s when the schema has not been generated" do
      FileUtils.rm(root.join("openapi", "public_api.yaml"))

      get "/schemas/public_api.yaml"

      expect(last_response.status).to eq(404)
    end
  end

  describe "GET /" do
    it "404s while the UI is disabled" do
      get "/"

      expect(last_response.status).to eq(404)
    end

    context "with the UI enabled" do
      before { OpenapiRuby.configuration.ui_enabled = true }

      it "renders Swagger UI pointing at the mounted schema path" do
        get "/", {}, "SCRIPT_NAME" => "/api-docs"

        expect(last_response.status).to eq(200)
        expect(last_response.headers["content-type"]).to eq("text/html")
        expect(last_response.body).to include('url: "/api-docs/schemas/public_api.yaml"')
      end

      it "serves the oauth2 redirect page" do
        get "/oauth2-redirect.html"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("Swagger UI: OAuth2 Redirect")
      end

      it "switches to the multi-schema layout" do
        OpenapiRuby.configuration.schemas[:admin_api] = {info: {title: "Admin API", version: "1.0"}}

        get "/", {}, "SCRIPT_NAME" => "/api-docs"

        expect(last_response.body).to include("StandaloneLayout")
        expect(last_response.body).to include('{"url":"/api-docs/schemas/admin_api.yaml","name":"Admin API"}')
      end
    end
  end

  it "405s on non-GET requests" do
    post "/schemas"

    expect(last_response.status).to eq(405)
  end

  it "404s on unknown paths" do
    get "/nope"

    expect(last_response.status).to eq(404)
  end

  context "with JSON output configured" do
    before { OpenapiRuby.configuration.schema_output_format = :json }

    it "serves the JSON document" do
      File.write(root.join("openapi", "public_api.json"), {"openapi" => "3.1.0"}.to_json)

      get "/schemas/public_api.json"

      expect(last_response.headers["content-type"]).to eq("application/json")
      expect(JSON.parse(last_response.body)).to eq("openapi" => "3.1.0")
    end
  end
end
