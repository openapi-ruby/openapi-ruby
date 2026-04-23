# frozen_string_literal: true

module OpenapiRuby
  module DSL
    class Context
      attr_reader :path_template, :operations, :path_parameters, :schema_name

      HTTP_METHODS = %i[get post put patch delete head options trace].freeze

      def initialize(path_template, schema_name: nil)
        @path_template = path_template
        @schema_name = schema_name
        @operations = {}
        @path_parameters = []
      end

      def parameter(attributes = {})
        param = deep_stringify(attributes)
        param["required"] = true if param["in"] == "path"
        @path_parameters << param
      end

      HTTP_METHODS.each do |method|
        define_method(method) do |summary = nil, &block|
          op = OperationContext.new(method, summary)
          op.instance_eval(&block) if block
          @operations[method.to_s] = op
          op
        end
      end

      def to_openapi
        result = {}

        result["parameters"] = @path_parameters if @path_parameters.any?

        @operations.each do |verb, op|
          result[verb] = op.to_openapi
        end

        result
      end

      private

      def deep_stringify(value)
        case value
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
