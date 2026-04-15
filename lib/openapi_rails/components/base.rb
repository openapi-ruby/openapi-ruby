# frozen_string_literal: true

module OpenapiRails
  module Components
    module Base
      def self.included(base)
        base.extend ClassMethods
        base.class_attribute :_schema_definition, default: {}
        base.class_attribute :_schema_hidden, default: false
        base.class_attribute :_skip_key_transformation, default: false
        base.class_attribute :_component_type, default: :schemas
        base.class_attribute :_component_scopes, default: []

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
          Registry.instance.register(subclass) if subclass.name
        end

        def schema(definition = nil)
          if definition
            self._schema_definition = _schema_definition.deep_merge(deep_stringify(definition))
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
          self._component_scopes = scopes.flatten.map(&:to_sym)
        end

        def component_name
          (name || "Anonymous").demodulize
        end

        def to_openapi
          definition = _schema_definition.deep_dup

          if _component_type == :schemas
            definition["title"] ||= component_name
          end

          if should_transform_keys?
            KeyTransformer.camelize_keys(definition)
          else
            definition
          end
        end

        private

        def should_transform_keys?
          !_skip_key_transformation && OpenapiRails.configuration.camelize_keys
        end

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
end
