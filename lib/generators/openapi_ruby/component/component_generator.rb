# frozen_string_literal: true

module OpenapiRuby
  module Generators
    class ComponentGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      argument :component_type, type: :string, default: "schemas",
        desc: "Component type (schemas, parameters, security_schemes, request_bodies, responses, headers, examples, links, callbacks)"

      desc "Generate an OpenAPI schema component class"

      def create_component_file
        component_path = OpenapiRuby.configuration.component_paths.first
        template "component.rb.tt",
          File.join(component_path, component_type, "#{file_name}.rb")
      end

      private

      def class_name
        name.camelize
      end

      def module_name
        component_type.camelize
      end

      def component_type_symbol
        component_type.to_sym
      end

      def needs_component_type?
        component_type != "schemas"
      end

      def openapi_component_type
        case component_type
        when "security_schemes" then "securitySchemes"
        when "request_bodies" then "requestBodies"
        else component_type
        end
      end
    end
  end
end
