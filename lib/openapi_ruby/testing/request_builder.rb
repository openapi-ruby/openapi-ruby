# frozen_string_literal: true

module OpenapiRuby
  module Testing
    class RequestBuilder
      attr_reader :method, :path, :params, :headers, :body

      def initialize(operation_context, response_context, param_values: {}, header_values: {}, body_value: nil)
        @operation = operation_context
        @response = response_context
        @param_values = deep_stringify(param_values)
        @header_values = deep_stringify(header_values)
        @body_value = body_value
        @method = operation_context.verb.to_sym
      end

      def build
        @path = expand_path
        @params = build_query_params
        @headers = build_headers
        @body = build_body
        self
      end

      private

      def expand_path
        @operation.parameters.select do |p|
          p["in"] == "path"
        end.each_with_object(@response || "") do |_param, tmpl|
          # This is just the template — actual path is built from the context's path_template
        end
      end

      def build_query_params
        query_params = @operation.parameters.select { |p| p["in"] == "query" }
        result = {}
        query_params.each do |param|
          name = param["name"]
          result[name] = @param_values[name] if @param_values.key?(name)
        end
        result
      end

      def build_headers
        header_params = @operation.parameters.select { |p| p["in"] == "header" }
        result = @header_values.dup
        header_params.each do |param|
          name = param["name"]
          result[name] = @param_values[name] if @param_values.key?(name) && !result.key?(name)
        end

        # Set Content-Type from consumes if body is present
        if @body_value && !result.key?("Content-Type")
          consumes = @operation.instance_variable_get(:@consumes_list)
          result["Content-Type"] = consumes&.first || "application/json"
        end

        result
      end

      def build_body
        return nil unless @body_value

        content_type = @headers&.fetch("Content-Type", nil)
        consumes = @operation.instance_variable_get(:@consumes_list)
        content_type ||= consumes&.first

        if content_type&.include?("form-data") || content_type&.include?("x-www-form-urlencoded")
          @body_value
        elsif @body_value.is_a?(Hash) || @body_value.is_a?(Array)
          @body_value.to_json
        else
          @body_value
        end
      end

      def deep_stringify(value)
        case value
        when Hash
          value.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
        else
          value
        end
      end
    end
  end
end
