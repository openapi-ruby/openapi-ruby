# frozen_string_literal: true

module OpenapiRuby
  module Generator
    class SchemaWriter
      def self.generate_all!
        config = OpenapiRuby.configuration

        if config.schemas.empty?
          warn "[openapi_ruby] No schemas configured, skipping generation"
          return
        end

        config.schemas.each do |name, schema_config|
          new(name, schema_config).write!
        end
      end

      def initialize(schema_name, schema_config)
        @schema_name = schema_name
        @schema_config = schema_config
      end

      def write!
        document = build_document
        validate_document!(document) if OpenapiRuby.configuration.strict_reference_validation
        output_path = File.join(output_dir, filename)
        FileUtils.mkdir_p(output_dir)
        File.write(output_path, format_output(document))
        output_path
      end

      def build_document
        builder = Core::DocumentBuilder.new(@schema_config)

        # Merge paths from DSL metadata
        DSL::MetadataStore.contexts_for(@schema_name).each do |context|
          builder.add_path(context.path_template, context.to_openapi)
        end

        # Merge components from registry
        scope = @schema_config[:component_scope]
        components = Components::Registry.instance.to_openapi_hash(scope: scope)
        builder.merge_components(components)

        builder.build
      end

      private

      def output_dir
        OpenapiRuby.configuration.schema_output_dir
      end

      def filename
        ext = (OpenapiRuby.configuration.schema_output_format == :json) ? "json" : "yaml"
        "#{@schema_name}.#{ext}"
      end

      def validate_document!(document)
        errors = document.validate
        return if errors.empty?

        error_messages = errors.first(10).map { |e| e["error"] || e.to_s }
        warn "[openapi_ruby] Generated schema '#{@schema_name}' has validation errors:\n#{error_messages.join("\n")}"
      end

      def format_output(document)
        if OpenapiRuby.configuration.schema_output_format == :json
          document.to_json
        else
          document.to_yaml
        end
      end
    end
  end
end
