# frozen_string_literal: true

module OpenapiRuby
  module Middleware
    class SchemaResolver
      def initialize(spec_path: nil, document: nil, strict_reference_validation: true)
        @spec_path = spec_path
        @document = document
        @strict_reference_validation = strict_reference_validation
        @path_matcher = nil
        @schemer = nil
      end

      def document
        @document ||= load_document.tap { |doc| validate_document!(doc) }
      end

      def schemer
        @schemer ||= JSONSchemer.openapi(document)
      end

      def path_matcher
        @path_matcher ||= PathMatcher.new(document.fetch("paths", {}).keys)
      end

      def find_operation(method, request_path)
        result = path_matcher.match(request_path)
        return nil unless result

        template, path_params = result
        operation = document.dig("paths", template, method.downcase)
        return nil unless operation

        {
          operation: operation,
          template: template,
          path_params: path_params
        }
      end

      private

      def validate_document!(doc)
        return unless @strict_reference_validation

        schemer = JSONSchemer.openapi(doc)
        errors = schemer.validate.to_a
        return if errors.empty?

        error_messages = errors.first(5).map { |e| e["error"] || e.to_s }
        raise OpenapiRuby::ConfigurationError,
          "OpenAPI document validation failed:\n#{error_messages.join("\n")}"
      end

      def load_document
        raise ConfigurationError, "No spec_path configured for middleware" unless @spec_path

        raw = File.read(@spec_path)
        if @spec_path.end_with?(".yaml", ".yml")
          YAML.safe_load(raw, permitted_classes: [Date, Time])
        else
          JSON.parse(raw)
        end
      end
    end
  end
end
