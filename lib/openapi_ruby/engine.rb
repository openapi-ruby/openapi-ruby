# frozen_string_literal: true

module OpenapiRuby
  class Engine < ::Rails::Engine
    isolate_namespace OpenapiRuby

    initializer "openapi_ruby.middleware" do |app|
      config = OpenapiRuby.configuration

      if config.request_validation != :disabled || config.response_validation != :disabled
        config.schemas.each do |name, schema_config|
          schema_path = resolve_schema_path(config, name)
          next unless schema_path && File.exist?(schema_path)

          resolver = Middleware::SchemaResolver.new(
            spec_path: schema_path,
            strict_reference_validation: config.strict_reference_validation
          )

          prefix = schema_config[:prefix]

          if config.request_validation != :disabled
            app.middleware.use Middleware::RequestValidation,
              schema_resolver: resolver,
              mode: config.request_validation,
              prefix: prefix
          end

          if config.response_validation != :disabled
            app.middleware.use Middleware::ResponseValidation,
              schema_resolver: resolver,
              mode: config.response_validation,
              prefix: prefix
          end
        end
      end
    end

    initializer "openapi_ruby.components" do
      config = OpenapiRuby.configuration
      config.component_paths.each do |path|
        expanded = Rails.root.join(path)
        next unless expanded.exist?

        # Auto-define modules for subdirectories (Schemas, Parameters, etc.)
        expanded.children.select(&:directory?).each do |dir|
          mod_name = dir.basename.to_s.camelize.to_sym
          Object.const_set(mod_name, Module.new) unless Object.const_defined?(mod_name)
        end

        Dir[expanded.join("**", "*.rb")].sort.each { |f| require f }
      end
    end

    private

    def resolve_schema_path(config, schema_name)
      ext = (config.schema_output_format == :json) ? "json" : "yaml"
      Rails.root.join(config.schema_output_dir, "#{schema_name}.#{ext}").to_s
    end
  end
end
