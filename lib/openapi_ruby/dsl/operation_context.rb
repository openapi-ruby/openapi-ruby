# frozen_string_literal: true

module OpenapiRuby
  module DSL
    class OperationContext
      attr_reader :verb, :summary, :parameters, :responses, :request_body_definition,
        :request_examples, :metadata

      def initialize(verb, summary = nil)
        @verb = verb.to_s
        @summary = summary
        @parameters = []
        @responses = {}
        @request_body_definition = nil
        @request_examples = []
        @metadata = {}
        @tags_list = []
        @consumes_list = []
        @produces_list = []
        @security_list = nil
      end

      def tags(*values)
        @tags_list.concat(values.flatten.map(&:to_s))
      end

      def operationId(id) # rubocop:disable Naming/MethodName
        @metadata["operationId"] = id.to_s
      end

      def description(text)
        @metadata["description"] = text.to_s
      end

      def deprecated(value = true)
        @metadata["deprecated"] = value
      end

      def consumes(*content_types)
        @consumes_list.concat(content_types.flatten)
      end

      def produces(*content_types)
        @produces_list.concat(content_types.flatten)
      end

      def security(schemes)
        @security_list = Array(schemes).map { |s| deep_stringify(s) }
      end

      def parameter(attributes = {})
        param = deep_stringify(attributes)
        param["required"] = true if param["in"] == "path"
        @parameters << param
      end

      def request_body(attributes = {})
        stringified = deep_stringify(attributes)

        # Shorthand: if schema is provided without content, wrap it in
        # content: { "application/json" => { schema: ... } }
        if stringified["schema"] && !stringified["content"]
          schema = stringified.delete("schema")
          stringified["content"] = {"application/json" => {"schema" => schema}}
        end

        @request_body_definition = stringified
      end

      def request_body_example(value:, name: "example", summary: nil)
        entry = {"value" => value, "name" => name.to_s}
        entry["summary"] = summary if summary
        @request_examples << entry
      end

      def response(status_code, description, hidden: false, &block)
        ctx = ResponseContext.new(status_code, description, hidden: hidden)
        ctx.produces(*@produces_list) if @produces_list.any?
        ctx.instance_eval(&block) if block

        key = status_code.to_s
        # Keep the first visible response for each status code. Subsequent responses
        # with the same code are test variants and should not overwrite the schema.
        # A visible response always wins over a hidden one.
        existing = @responses[key]
        @responses[key] = ctx if existing.nil? || (existing.hidden && !hidden)

        ctx
      end

      def to_openapi
        result = {}
        result["summary"] = @summary if @summary
        result["tags"] = @tags_list if @tags_list.any?
        result.merge!(@metadata)
        result["parameters"] = @parameters if @parameters.any?
        result["security"] = @security_list if @security_list

        result["requestBody"] = build_request_body if @request_body_definition

        result["responses"] = {}
        @responses.each do |code, ctx|
          next if ctx.hidden
          result["responses"][code] = ctx.to_openapi
        end

        result
      end

      private

      def build_request_body
        rb = @request_body_definition.dup

        if @request_examples.any? && rb["content"]
          rb["content"].each_value do |media_type|
            media_type["examples"] ||= {}
            @request_examples.each do |ex|
              entry = {"value" => ex["value"]}
              entry["summary"] = ex["summary"] if ex["summary"]
              media_type["examples"][ex["name"]] = entry
            end
          end
        end

        rb
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
