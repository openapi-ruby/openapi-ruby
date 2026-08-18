# frozen_string_literal: true

require "rack"

module OpenapiRuby
  # Serves the generated schema documents and the Swagger UI as a plain Rack
  # app, for hosts with no engine to mount:
  #
  #   # Hanami — config/routes.rb
  #   mount OpenapiRuby::RackApp, at: "/api-docs"
  #
  # Routes mirror the Rails engine's (config/routes.rb) so both hosts expose
  # the same paths. Schema URLs are derived from SCRIPT_NAME, so the app works
  # at any mount point.
  #
  # Deliberately not namespaced under OpenapiRuby::Rack: that constant would
  # shadow the top-level ::Rack for every file in this gem.
  class RackApp
    SCHEMA_PATH = %r{\A/schemas/(?<name>.+)\z}
    SCHEMA_EXTENSION = /\.(json|ya?ml)\z/

    def self.call(env)
      (@app ||= new).call(env)
    end

    def call(env)
      request = ::Rack::Request.new(env)
      return method_not_allowed unless request.get? || request.head?

      status, headers, body = case request.path_info
      when "", "/" then ui(request)
      when "/schemas" then schema_index
      when "/oauth2-redirect.html" then oauth2_redirect
      when SCHEMA_PATH then schema(::Regexp.last_match(:name), request)
      else not_found
      end

      # Drop the body ourselves: Rails runs Rack::Head above the engine, a bare
      # Hanami mount has nothing between the router and here.
      [status, headers, request.head? ? [] : body]
    end

    private

    def ui(request)
      return not_found unless OpenapiRuby.configuration.ui_enabled

      html = Serving.swagger_ui_html(
        schema_urls: schema_urls(request),
        ui_config: OpenapiRuby.configuration.ui_config
      )
      respond(200, "text/html", html)
    end

    def oauth2_redirect
      return not_found unless OpenapiRuby.configuration.ui_enabled

      respond(200, "text/html", File.read(Serving.oauth2_redirect_file))
    end

    def schema_index
      respond(200, "application/json", {schemas: Serving.schema_names}.to_json)
    end

    def schema(name, request)
      document = Serving.schema_document(name.sub(SCHEMA_EXTENSION, ""), request: request)
      return not_found unless document

      content, content_type = document
      respond(200, content_type, content)
    end

    def schema_urls(request)
      OpenapiRuby.configuration.schemas.map do |name, schema_config|
        {
          url: "#{request.script_name}/schemas/#{name}.#{Serving.schema_format}",
          name: schema_config.dig(:info, :title) || name.to_s
        }
      end
    end

    def respond(status, content_type, body, headers = {})
      [status, {"content-type" => content_type}.merge(headers), [body]]
    end

    def not_found
      respond(404, "application/json", {error: "Not found"}.to_json)
    end

    def method_not_allowed
      respond(405, "application/json", {error: "Method not allowed"}.to_json, "allow" => "GET, HEAD")
    end
  end
end
