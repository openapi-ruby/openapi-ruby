# frozen_string_literal: true

module OpenapiRuby
  module Components
    # Opt-in mixin that derives T::Struct `const` declarations from a
    # component's schema. Requires sorbet-runtime; load via
    # `require "openapi_ruby/sorbet"`.
    #
    #   class Schemas::UserInput < T::Struct
    #     include OpenapiRuby::Components::Base
    #     include OpenapiRuby::Components::TypedParams
    #
    #     schema(type: :object, required: %w[name], properties: {name: {type: :string}})
    #   end
    module TypedParams
      SCALAR_TYPES = {
        "string" => String,
        "integer" => Integer,
        "number" => T.any(Integer, Float),
        "boolean" => T::Boolean
      }.freeze

      def self.included(base)
        unless base < T::Struct
          raise ArgumentError, "#{base} must inherit from T::Struct to include TypedParams"
        end
        unless base < OpenapiRuby::Components::Base
          raise ArgumentError, "#{base} must include OpenapiRuby::Components::Base before TypedParams"
        end

        base.extend ClassMethods
        base.prepend RequiredNullableCheck
        base.send(:define_struct_props)
      end

      # T::Struct treats every T.nilable prop as optional, so a property the
      # schema requires but allows to be null must be checked on construction.
      module RequiredNullableCheck
        def initialize(hash = {})
          missing = self.class.required_nullable_props.reject { |name| hash.key?(name) }
          unless missing.empty?
            raise ArgumentError, "#{self.class.name}: missing required properties: #{missing.join(", ")}"
          end

          super
        end
      end

      module ClassMethods
        def required_nullable_props
          required = Array(_schema_definition["required"])
          (_schema_definition["properties"] || {}).filter_map do |name, spec|
            name.to_sym if required.include?(name) && nullable_spec?(spec)
          end
        end

        def schema(definition = nil)
          result = super
          define_struct_props if definition
          result
        end

        private

        def define_struct_props
          definition = _schema_definition
          required = Array(definition["required"])

          (definition["properties"] || {}).each do |name, spec|
            prop_name = name.to_sym
            type = struct_type_for(spec)

            if required.include?(name) && !nullable_spec?(spec)
              declare_struct_prop(prop_name, type)
            else
              declare_struct_prop(prop_name, T.nilable(type), default: nil)
            end
          end
        end

        # A T::Struct prop can't be redefined, so a later schema call that
        # changes an already-declared prop's type or nilability is rejected.
        def declare_struct_prop(prop_name, type, **options)
          existing = props[prop_name]
          if existing
            return if existing[:type_object] == T::Utils.coerce(type)

            raise ArgumentError,
              "#{name}: cannot change #{prop_name} from #{existing[:type_object]} to #{type} " \
              "after it was declared; set the full definition in a single schema call"
          end

          const prop_name, type, **options
        end

        def nullable_spec?(spec)
          spec["nullable"] == true || Array(spec["type"]).include?("null")
        end

        def struct_type_for(spec)
          return struct_class_for_ref(spec["$ref"]) if spec["$ref"]

          types = Array(spec["type"]).reject { |t| t == "null" }.map { |t| struct_type_for_name(t, spec) }
          case types.size
          when 0 then T.untyped
          when 1 then types.first
          else T.any(*types)
          end
        end

        def struct_type_for_name(type, spec)
          case type
          when *SCALAR_TYPES.keys
            SCALAR_TYPES.fetch(type)
          when "array"
            items = spec["items"]
            T::Array[items ? struct_type_for(items) : T.untyped]
          when "object"
            T::Hash[String, T.untyped]
          else
            T.untyped
          end
        end

        def struct_class_for_ref(ref)
          _, _, type, component = ref.split("/")
          klass = [module_parent, Object].filter_map { |scope|
            "#{scope}::#{component}".delete_prefix("Object::").safe_constantize
          }.first
          klass ||= registry_class_for(component, type.to_sym)

          unless klass && klass < TypedParams
            raise ArgumentError,
              "#{name}: cannot resolve #{ref} to a class that includes OpenapiRuby::Components::TypedParams"
          end

          klass
        end

        # Same short name, same component type, and a scope this component
        # shares (an unscoped component is visible everywhere). Ambiguity is an
        # error rather than a registration-order guess.
        def registry_class_for(component, type)
          candidates = Registry.instance.components_for(type).values.select { |c|
            c.component_name == component &&
              (c._component_scopes.empty? || _component_scopes.empty? || (c._component_scopes & _component_scopes).any?)
          }
          return candidates.first if candidates.size <= 1

          raise ArgumentError,
            "#{name}: #{component} is ambiguous (#{candidates.map(&:name).join(", ")}); " \
            "reference it by class instead"
        end
      end
    end
  end
end
