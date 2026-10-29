# typed: strict
# frozen_string_literal: true

require "openapi_ruby/sorbet"

module Tapioca
  module Dsl
    module Compilers
      # Emits RBI `const` readers for T::Struct components that include
      # OpenapiRuby::Components::TypedParams.
      #
      #   bin/tapioca dsl Schemas::UserInput
      class OpenapiRubyTypedParams < Compiler
        extend T::Sig

        ConstantType = type_member { {fixed: T.class_of(T::Struct)} }

        sig { override.returns(T::Enumerable[Module]) }
        def self.gather_constants
          all_classes.select { |klass| klass < OpenapiRuby::Components::TypedParams }
        end

        sig { override.void }
        def decorate
          root.create_path(constant) do |klass|
            params = constant.props.map do |name, rules|
              type = rules.fetch(:type_object).to_s
              klass.create_method(name.to_s, return_type: type)
              if rules.key?(:default)
                create_kw_opt_param(name.to_s, type: type, default: "nil")
              else
                create_kw_param(name.to_s, type: type)
              end
            end
            klass.create_method("initialize", parameters: params, return_type: "void")
          end
        end
      end
    end
  end
end
