# frozen_string_literal: true

require "singleton"

module OpenapiRuby
  module Components
    class Registry
      include Singleton

      def initialize
        @components = {}
      end

      def register(component_class)
        type = component_class._component_type
        key = component_class.registry_key

        @components[type] ||= {}

        if @components[type].key?(key) && @components[type][key] != component_class
          raise DuplicateComponentError, "Component '#{component_class.component_name}' already registered under #{type}"
        end

        @components[type][key] = component_class
      end

      def unregister(component_class)
        type = component_class._component_type
        key = component_class.registry_key
        @components[type]&.delete(key)
      end

      def components_for(type)
        @components[type] || {}
      end

      def all_types
        @components.keys
      end

      def all_registered_classes
        @components.values.flat_map(&:values)
      end

      def grouped_by_type
        @components.dup
      end

      def clear!
        @components = {}
      end

      def to_openapi_hash(scope: nil)
        result = {}
        @components.each do |type, components|
          type_key = type.to_s
          result[type_key] = {}
          components.each_value do |klass|
            next if klass._schema_hidden
            next if scope && !klass._component_scopes.empty? && !klass._component_scopes.include?(scope)

            result[type_key][klass.component_name] = klass.to_openapi
          end
          result.delete(type_key) if result[type_key].empty?
        end
        result
      end
    end
  end
end
