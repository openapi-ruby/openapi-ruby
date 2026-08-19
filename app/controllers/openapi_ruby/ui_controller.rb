# frozen_string_literal: true

module OpenapiRuby
  class UiController < ActionController::Base
    layout false

    def index
      html = Serving.swagger_ui_html(
        schema_urls: schema_urls,
        ui_config: OpenapiRuby.configuration.ui_config
      )
      render html: html.html_safe
    end

    def oauth2_redirect
      render file: Serving.oauth2_redirect_file, layout: false, content_type: "text/html"
    end

    private

    def schema_urls
      OpenapiRuby.configuration.schemas.map do |name, schema_config|
        {
          url: openapi_ruby.schema_path(name.to_s, format: Serving.schema_format),
          name: schema_config.dig(:info, :title) || name.to_s
        }
      end
    end
  end
end
