# frozen_string_literal: true

module OpenapiRails
  module Components
    class Loader
      attr_reader :paths

      def initialize(paths: nil, scope: nil)
        @paths = paths || OpenapiRails.configuration.component_paths
        @scope = scope&.to_sym
      end

      def load!
        component_files.each { |f| require f }
        self
      end

      def to_openapi_hash
        Registry.instance.to_openapi_hash(scope: @scope)
      end

      def schemas
        filter_type(:schemas)
      end

      def parameters
        filter_type(:parameters)
      end

      def security_schemes
        filter_type(:securitySchemes)
      end

      def request_bodies
        filter_type(:requestBodies)
      end

      def responses
        filter_type(:responses)
      end

      def headers
        filter_type(:headers)
      end

      def examples
        filter_type(:examples)
      end

      def links
        filter_type(:links)
      end

      def callbacks
        filter_type(:callbacks)
      end

      private

      def component_files
        @paths.flat_map do |path|
          expanded = File.expand_path(path)
          Dir[File.join(expanded, "**", "*.rb")].sort
        end
      end

      def filter_type(type)
        to_openapi_hash[type.to_s] || {}
      end
    end
  end
end
