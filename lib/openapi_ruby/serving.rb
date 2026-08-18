# frozen_string_literal: true

module OpenapiRuby
  # Host-neutral logic behind the served schema documents and the Swagger UI.
  # The Rails controllers and RackApp are both thin shells over this, so the
  # two hosts cannot drift apart.
  module Serving
    module_function

    def schema_names
      OpenapiRuby.configuration.schemas.keys.map(&:to_s)
    end

    def schema_config_for(schema_name)
      OpenapiRuby.configuration.schemas[schema_name.to_sym]
    end

    def schema_file_path(schema_name)
      config = OpenapiRuby.configuration
      ext = (config.schema_output_format == :json) ? "json" : "yaml"
      File.join(OpenapiRuby.app_root, config.schema_output_dir, "#{schema_name}.#{ext}")
    end

    def schema_format
      (OpenapiRuby.configuration.schema_output_format == :json) ? :json : :yaml
    end

    # Returns [content, content_type], or nil when the schema is unknown or
    # has not been generated yet — callers turn that into a 404.
    #
    # `request` is handed to the configured :openapi_filter untouched. Rails
    # passes an ActionDispatch::Request and RackApp a Rack::Request; the hook
    # only ever needs the shared Rack request API.
    def schema_document(schema_name, request: nil)
      schema_config = schema_config_for(schema_name)
      return nil unless schema_config

      file_path = schema_file_path(schema_name)
      return nil unless File.exist?(file_path)

      content = File.read(file_path)

      if schema_config[:openapi_filter]
        doc = parse_content(file_path, content)
        schema_config[:openapi_filter].call(doc, request)
        content = serialize_doc(file_path, doc)
      end

      [content, content_type_for(file_path)]
    end

    def content_type_for(file_path)
      file_path.end_with?(".json") ? "application/json" : "application/x-yaml"
    end

    def parse_content(file_path, content)
      if file_path.end_with?(".json")
        JSON.parse(content)
      else
        YAML.safe_load(content, permitted_classes: [Date, Time])
      end
    end

    def serialize_doc(file_path, doc)
      if file_path.end_with?(".json")
        JSON.pretty_generate(doc)
      else
        doc.to_yaml
      end
    end

    def oauth2_redirect_file
      File.join(gem_root, "app", "views", "openapi_ruby", "oauth2_redirect.html")
    end

    def gem_root
      File.expand_path("../..", __dir__)
    end

    # `schema_urls` is an array of {url:, name:} — the caller builds them,
    # since only it knows how the docs are mounted.
    def swagger_ui_html(schema_urls:, ui_config: {})
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <title>#{ui_config[:title] || "API Documentation"}</title>
          <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
          <style>
            html { box-sizing: border-box; overflow-y: scroll; }
            *, *:before, *:after { box-sizing: inherit; }
            body { margin: 0; background: #fafafa; }
          </style>
        </head>
        <body>
          <div id="swagger-ui"></div>
          <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
          <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js"></script>
          <script>
            SwaggerUIBundle({
              #{schema_urls_js(schema_urls)},
              dom_id: '#swagger-ui',
              deepLinking: true,
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIStandalonePreset
              ],
              plugins: [
                SwaggerUIBundle.plugins.DownloadUrl
              ],
              layout: "#{(schema_urls.size > 1) ? "StandaloneLayout" : "BaseLayout"}",
              #{ui_config_js(ui_config)}
            });
          </script>
        </body>
        </html>
      HTML
    end

    def schema_urls_js(schema_urls)
      if schema_urls.size > 1
        "urls: #{schema_urls.to_json}"
      else
        "url: \"#{schema_urls.first&.fetch(:url)}\""
      end
    end

    def ui_config_js(ui_config)
      ui_config.except(:title).map { |k, v|
        "#{k}: #{v.to_json}"
      }.join(",\n          ")
    end
  end
end
