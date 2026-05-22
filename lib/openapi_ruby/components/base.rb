# frozen_string_literal: true

module OpenapiRuby
  module Components
    module Base
      def self.included(base)
        # Guard against re-including in subclasses that already inherited Base.
        # Re-running class_attribute with default: would overwrite inherited values.
        already_included = base.respond_to?(:_schema_definition)

        base.extend ClassMethods unless already_included

        unless already_included
          base.class_attribute :_schema_definition, default: {}
          base.class_attribute :_schema_hidden, default: false
          base.class_attribute :_skip_key_transformation, default: false
          base.class_attribute :_component_type, default: :schemas
          base.class_attribute :_component_scopes, default: []
          base.class_attribute :_component_scopes_explicitly_set, default: false
        end

        Registry.instance.register(base) if base.name
      end

      module ClassMethods
        def inherited(subclass)
          super
          subclass._schema_definition = _schema_definition.deep_dup
          subclass._schema_hidden = false
          subclass._skip_key_transformation = _skip_key_transformation
          subclass._component_type = _component_type
          subclass._component_scopes = _component_scopes.dup
          subclass._component_scopes_explicitly_set = _component_scopes_explicitly_set
          Registry.instance.register(subclass) if subclass.name
        end

        def schema(definition = nil)
          if definition
            stringified = deep_stringify(definition)
            self._schema_definition = deep_merge_with_array_concat(_schema_definition, stringified)
          end
          _schema_definition
        end

        def schema_hidden(value = true)
          self._schema_hidden = value
        end

        def skip_key_transformation(value = true)
          self._skip_key_transformation = value
        end

        def component_type(type)
          Registry.instance.unregister(self)
          self._component_type = type.to_sym
          Registry.instance.register(self)
        end

        def component_scopes(*scopes)
          Registry.instance.unregister(self)
          self._component_scopes = scopes.flatten.map(&:to_sym)
          self._component_scopes_explicitly_set = true
          Registry.instance.register(self)
        end

        def shared_component
          self._component_scopes = []
          self._component_scopes_explicitly_set = true
        end

        def transform_enum_key(key)
          key = ActiveSupport::Inflector.underscore(key.to_s)
          key.parameterize(separator: "_").upcase
        end

        def component_name
          (name || "Anonymous").demodulize
        end

        def registry_key
          if _component_scopes.empty?
            component_name
          else
            "#{_component_scopes.sort.join("_")}:#{component_name}"
          end
        end

        def to_ref
          OpenapiRuby::Core::RefResolver.ref_object(_component_type, component_name)
        end

        def to_openapi
          definition = _schema_definition.deep_dup

          definition["title"] ||= component_name if _component_type == :schemas

          if should_transform_keys?
            KeyTransformer.camelize_keys(definition)
          else
            definition
          end
        end

        def permitted_params
          properties = _schema_definition["properties"]
          return [] unless properties

          build_permit_list(properties)
        end

        private

        def build_permit_list(properties)
          properties.map do |key, spec|
            param_name = key.to_sym
            type = spec["type"]

            if type == "array"
              items = spec["items"]
              if items && items["type"] == "object" && items["properties"]
                {param_name => build_permit_list(items["properties"])}
              else
                {param_name => []}
              end
            elsif type == "object" && spec["properties"]
              {param_name => build_permit_list(spec["properties"])}
            else
              param_name
            end
          end
        end

        def should_transform_keys?
          !_skip_key_transformation && OpenapiRuby.configuration.camelize_keys
        end

        # Deep merge that concatenates arrays instead of replacing them,
        # matching the behavior of rswag-schema_components' deeper_merge.
        # This ensures inherited schema properties (like `required`) are merged correctly.
        def deep_merge_with_array_concat(base, override)
          base.merge(override) do |_key, old_val, new_val|
            if old_val.is_a?(Hash) && new_val.is_a?(Hash)
              deep_merge_with_array_concat(old_val, new_val)
            elsif old_val.is_a?(Array) && new_val.is_a?(Array)
              (old_val + new_val).uniq
            else
              new_val
            end
          end
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
end
