# frozen_string_literal: true

module OpenapiRuby
  module Middleware
    # Installs the runtime validation middleware onto a Rack stack. Anything
    # responding to #use works — Rails' `app.middleware` and Hanami's
    # `config.middleware` share that much API, so no host branching is needed.
    module Installer
      module_function

      def install!(stack, root: OpenapiRuby.app_root)
        config = OpenapiRuby.configuration

        return if ENV["OPENAPI_RUBY_GENERATING"]
        return if config.request_validation == :disabled && config.response_validation == :disabled

        config.schemas.each do |name, schema_config|
          schema_path = resolve_schema_path(config, name, root)
          next unless schema_path && File.exist?(schema_path)

          resolver = SchemaResolver.new(
            spec_path: schema_path,
            strict_reference_validation: config.strict_reference_validation
          )

          prefix = schema_config[:prefix]

          if config.request_validation != :disabled
            stack.use RequestValidation,
              schema_resolver: resolver,
              mode: config.request_validation,
              prefix: prefix
          end

          if config.response_validation != :disabled
            stack.use ResponseValidation,
              schema_resolver: resolver,
              mode: config.response_validation,
              prefix: prefix
          end
        end
      end

      def resolve_schema_path(config, schema_name, root)
        ext = (config.schema_output_format == :json) ? "json" : "yaml"
        File.join(root.to_s, config.schema_output_dir, "#{schema_name}.#{ext}")
      end
    end
  end
end
