# frozen_string_literal: true

module OpenapiRails
  module Components
    module KeyTransformer
      module_function

      def camelize_keys(hash)
        transform_keys(hash) { |key| camelize(key) }
      end

      def transform_keys(value, &block)
        case value
        when Hash
          value.each_with_object({}) do |(k, v), result|
            new_key = block.call(k.to_s)
            result[new_key] = transform_keys(v, &block)
          end
        when Array
          value.map { |v| transform_keys(v, &block) }
        else
          value
        end
      end

      def camelize(key)
        key = key.to_s
        return key if key.start_with?("$")

        parts = key.split("_")
        parts[0] + parts[1..].map(&:capitalize).join
      end
    end
  end
end
