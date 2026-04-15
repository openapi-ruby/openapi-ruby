# frozen_string_literal: true

module OpenapiRails
  module Core
    module RefResolver
      module_function

      def ref_path(component_type, name)
        "#/components/#{component_type}/#{name}"
      end

      def ref_object(component_type, name)
        { "$ref" => ref_path(component_type, name) }
      end

      def ref?(value)
        value.is_a?(Hash) && value.key?("$ref")
      end

      def resolve(ref_string, document)
        path = ref_string.delete_prefix("#/").split("/")
        path.reduce(document) { |node, segment| node&.dig(segment) }
      end
    end
  end
end
