# frozen_string_literal: true

module OpenapiRuby
  module Core
    class DocumentBuilder
      def initialize(spec_config = {})
        @spec_config = spec_config
        @document = Document.new(
          info: spec_config[:info] || {},
          servers: spec_config[:servers] || [],
          openapi_version: spec_config[:openapi_version] || Document::DEFAULT_OPENAPI_VERSION
        )
        @paths = {}
        @components = {}
        @security = []
        @tags = []
      end

      def add_path(template, operations)
        @paths[template] ||= {}
        @paths[template].deep_merge!(operations)
      end

      def merge_components(components_hash)
        @components.deep_merge!(components_hash)
      end

      def add_security(security)
        @security.concat(Array(security))
      end

      def add_tag(tag)
        @tags << tag unless @tags.any? { |t| t["name"] == tag["name"] }
      end

      def build
        inject_validation_error_responses! if OpenapiRuby.configuration.auto_validation_error_response
        @paths.each { |template, path_item| @document.add_path(template, path_item) }
        @document.set_components(@components)
        @document.set_security(@security)
        @document.set_tags(@tags)
        @document
      end

      def to_h
        build.to_h
      end

      private

      def inject_validation_error_responses!
        # Add SchemaValidationError response component
        @components["responses"] ||= {}
        @components["responses"]["SchemaValidationError"] ||= {
          "description" => "Request validation failed",
          "content" => {
            "application/json" => {
              "schema" => validation_error_component_schema
            }
          }
        }

        # Add 400 to operations that have parameters or a request body
        @paths.each_value do |path_item|
          path_params = path_item["parameters"]

          path_item.each do |key, operation|
            next unless operation.is_a?(Hash) && operation.key?("responses")
            next if key == "parameters"

            has_params = operation.key?("parameters") || path_params
            has_body = operation.key?("requestBody")
            next unless has_params || has_body

            operation["responses"]["400"] ||= {"$ref" => "#/components/responses/SchemaValidationError"}
          end
        end
      end

      def validation_error_component_schema
        custom = OpenapiRuby.configuration.validation_error_schema
        return custom if custom

        {
          "type" => "object",
          "properties" => {
            "error" => {"type" => "string"},
            "details" => {
              "type" => "array",
              "items" => {"type" => "string"}
            }
          },
          "required" => %w[error details]
        }
      end
    end
  end
end
