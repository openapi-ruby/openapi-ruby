# frozen_string_literal: true

module OpenapiRuby
  class Engine < ::Rails::Engine
    isolate_namespace OpenapiRuby

    initializer "openapi_ruby.middleware" do |app|
      Middleware::Installer.install!(app.middleware)
    end
  end
end
