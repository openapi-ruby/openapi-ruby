# frozen_string_literal: true

module OpenapiRuby
  module DSL
    class ResponseContext
      attr_reader :status_code, :description, :schema_definition, :headers, :examples, :links, :hidden

      def initialize(status_code, description, hidden: false)
        @status_code = status_code.to_s
        @description = description
        @hidden = hidden
        @schema_definition = nil
        @headers = {}
        @examples = {}
        @links = {}
        @content_types = nil
      end

      def schema(definition)
        @schema_definition = normalize(definition)
      end

      def header(name, attributes = {})
        @headers[name.to_s] = normalize(attributes)
      end

      def example(content_type, value:, name: "example", summary: nil, description: nil)
        @examples[content_type] ||= {}
        entry = {"value" => value}
        entry["summary"] = summary if summary
        entry["description"] = description if description
        @examples[content_type][name.to_s] = entry
      end

      def produces(*content_types)
        @content_types = content_types.flatten
      end

      def to_openapi
        result = {"description" => @description}

        if @schema_definition
          types = @content_types || ["application/json"]
          result["content"] = {}
          types.each do |ct|
            media = {"schema" => @schema_definition}
            media["examples"] = @examples[ct] if @examples.key?(ct)
            result["content"][ct] = media
          end
        end

        result["headers"] = build_headers if @headers.any?
        result["links"] = @links unless @links.empty?
        result
      end

      private

      def build_headers
        @headers.transform_values do |attrs|
          h = {}
          h["description"] = attrs["description"] if attrs["description"]
          h["required"] = attrs["required"] if attrs.key?("required")
          h["schema"] = attrs["schema"] if attrs["schema"]
          h
        end
      end

      def normalize(value)
        deep_stringify(value)
      end

      def deep_stringify(value)
        case value
        when Class
          if value < OpenapiRuby::Components::Base
            value.to_ref
          else
            raise ArgumentError, "#{value} is not an OpenapiRuby component"
          end
        when Hash
          value.each_with_object({}) { |(k, v), h| h[k.to_s] = deep_stringify(v) }
        when Array
          value.map { |v| deep_stringify(v) }
        when Symbol
          value.to_s
        else
          value
        end
      end
    end
  end
end
