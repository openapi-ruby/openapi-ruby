# frozen_string_literal: true

module OpenapiRuby
  class UiController < ActionController::Base
    layout false

    def index
      return head :not_found unless OpenapiRuby.configuration.ui_enabled

      config = OpenapiRuby.configuration
      @schemas = config.schemas
      @ui_config = config.ui_config

      render html: swagger_ui_html.html_safe
    end

    def oauth2_redirect
      return head :not_found unless OpenapiRuby.configuration.ui_enabled

      file = File.join(OpenapiRuby::Engine.root, "app", "views", "openapi_ruby", "oauth2_redirect.html")
      render file: file, layout: false, content_type: "text/html"
    end

    private

    def schema_format
      (OpenapiRuby.configuration.schema_output_format == :json) ? :json : :yaml
    end

    def swagger_ui_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <title>#{@ui_config[:title] || "API Documentation"}</title>
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
          <script>
            SwaggerUIBundle({
              #{schema_urls_js},
              dom_id: '#swagger-ui',
              deepLinking: true,
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIBundle.SwaggerUIStandalonePreset
              ],
              layout: "#{@schemas.size > 1 ? "StandaloneLayout" : "BaseLayout"}",
              #{ui_config_js}
            });
          </script>
        </body>
        </html>
      HTML
    end

    def schema_urls_js
      fmt = schema_format
      if @schemas.size > 1
        urls = @schemas.map { |name, schema_config|
          title = schema_config.dig(:info, :title) || name.to_s
          url = openapi_ruby.schema_path(name.to_s, format: fmt)
          {url: url, name: title}
        }
        "urls: #{urls.to_json}"
      else
        name = @schemas.keys.first.to_s
        url = openapi_ruby.schema_path(name, format: fmt)
        "url: \"#{url}\""
      end
    end

    def ui_config_js
      @ui_config.except(:title).map { |k, v|
        "#{k}: #{v.to_json}"
      }.join(",\n          ")
    end
  end
end
