# frozen_string_literal: true

module OpenapiRuby
  module Generators
    class ComponentGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      argument :component_type, type: :string, default: "schemas",
        desc: "Component type (schemas, parameters, security_schemes, request_bodies, responses, headers, examples, links, callbacks)"

      desc "Generate an OpenAPI schema component class"

      def create_component_file
        template "component.rb.tt",
          File.join(component_path, component_type, "#{file_name}.rb")
      end

      private

      # Components::Loader only looks under the configured paths, so anything
      # written to a hardcoded app/api_components is invisible on hosts that
      # default elsewhere (Hanami) or configure their own.
      def component_path
        path = OpenapiRuby.configuration.component_paths.first ||
          Configuration.default_component_paths.first
        relativize(path)
      end

      # An initializer may hold an absolute Rails.root.join(...) path; Thor
      # reports the destination verbatim, and an absolute one reads as noise.
      def relativize(path)
        pathname = Pathname.new(path)
        return path unless pathname.absolute?

        pathname.relative_path_from(Pathname.new(destination_root)).to_s
      rescue ArgumentError
        path
      end

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
