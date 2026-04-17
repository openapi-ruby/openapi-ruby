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
        name = component_class.name || "Anonymous"

        @components[type] ||= {}

        check_for_duplicate!(component_class, type)

        # Use the full class name as key to avoid collisions between
        # same-named components in different scopes (e.g., Internal::V1::Schemas::PaginatedCollection
        # vs Mobile::V1::Schemas::PaginatedCollection). Scope filtering happens in to_openapi_hash.
        @components[type][name] = component_class
      end

      def unregister(component_class)
        type = component_class._component_type
        name = component_class.name || "Anonymous"
        @components[type]&.delete(name)
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

      private

      def check_for_duplicate!(component_class, type)
        short_name = component_class.component_name
        new_scopes = component_class._component_scopes
        new_scopes_set = component_class._component_scopes_explicitly_set

        @components[type]&.each_value do |existing|
          next if existing.name == component_class.name
          next unless existing.component_name == short_name

          existing_scopes = existing._component_scopes
          existing_scopes_set = existing._component_scopes_explicitly_set

          # Skip when scopes haven't been explicitly configured yet — during initial
          # loading, components are registered with empty default scopes before the Loader
          # assigns inferred scopes. Only check for duplicates when both sides have
          # explicitly set their scopes.
          next unless new_scopes_set && existing_scopes_set

          if scopes_overlap?(new_scopes, existing_scopes)
            raise DuplicateComponentError,
              "Component '#{short_name}' is already registered as #{type} " \
              "(existing: #{existing.name}, new: #{component_class.name})"
          end
        end
      end

      def scopes_overlap?(a, b)
        return true if a.empty? && b.empty?
        return true if a.empty? || b.empty?
        (a & b).any?
      end

      public

      def to_openapi_hash(scope: nil)
        result = {}
        @components.each do |type, components|
          type_key = type.to_s
          result[type_key] = {}
          components.each_value do |klass|
            next if klass._schema_hidden
            # When filtering by scope:
            # - Components with matching scope: included
            # - Components explicitly marked as shared (empty scopes + explicitly_set): included
            # - Components with non-matching scope: excluded
            # - Components with no scope assigned (empty scopes + NOT explicitly_set): excluded
            if scope
              if klass._component_scopes.empty?
                next unless klass._component_scopes_explicitly_set
              else
                next unless klass._component_scopes.include?(scope)
              end
            end

            result[type_key][klass.component_name] = klass.to_openapi
          end
          result.delete(type_key) if result[type_key].empty?
        end
        result
      end
    end
  end
end
