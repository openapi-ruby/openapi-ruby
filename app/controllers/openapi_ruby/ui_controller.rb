# frozen_string_literal: true

module OpenapiRuby
  class UiController < ActionController::Base
    layout false

    def index
      config = OpenapiRuby.configuration
      @schemas = config.schemas
      @ui_config = config.ui_config
      @oauth_config = resolve_oauth_config(config.oauth_config)

      render html: swagger_ui_html.html_safe
    end

    def oauth2_redirect
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
          <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js"></script>
          <script>
            const ui = SwaggerUIBundle({
              #{schema_urls_js},
              dom_id: '#swagger-ui',
              deepLinking: true,
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIStandalonePreset
              ],
              plugins: [
                SwaggerUIBundle.plugins.DownloadUrl
              ],
              layout: "#{(@schemas.size > 1) ? "StandaloneLayout" : "BaseLayout"}",
              #{ui_config_js}
            });#{init_oauth_js}
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
        "urls: #{script_safe_json(urls)}"
      else
        name = @schemas.keys.first.to_s
        url = openapi_ruby.schema_path(name, format: fmt)
        "url: #{script_safe_json(url)}"
      end
    end

    def ui_config_js
      @ui_config.except(:title).map { |k, v|
        "#{k}: #{script_safe_json(v)}"
      }.join(",\n          ")
    end

    def resolve_oauth_config(cfg)
      return {} if cfg.nil?
      result = cfg.respond_to?(:call) ? cfg.call(self) : cfg
      result || {}
    end

    def init_oauth_js
      return "" if @oauth_config.empty?

      "\n            ui.initOAuth(#{script_safe_json(@oauth_config)});"
    end

    # Encodes values for safe interpolation into an HTML <script> block.
    # script_safe: true escapes `</`, U+2028, U+2029 so a string value can't
    # close the surrounding <script> tag or break parsing.
    def script_safe_json(value)
      JSON.generate(value, script_safe: true)
    end
  end
end
