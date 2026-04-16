# frozen_string_literal: true

module OpenapiRuby
  module Core
    class DocumentBuilder
      def initialize(spec_config = {})
        @spec_config = spec_config
        @document = Document.new(
          info: spec_config[:info] || {},
          servers: spec_config[:servers] || [],
          openapi_version: spec_config[:openapi_version] || Document::DEFAULT_OPENAPI_VERSION
        )
        @paths = {}
        @components = {}
        @security = []
        @tags = []
      end

      def add_path(template, operations)
        @paths[template] ||= {}
        @paths[template].deep_merge!(operations)
      end

      def merge_components(components_hash)
        @components.deep_merge!(components_hash)
      end

      def add_security(security)
        @security.concat(Array(security))
      end

      def add_tag(tag)
        @tags << tag unless @tags.any? { |t| t["name"] == tag["name"] }
      end

      def build
        @paths.each { |template, path_item| @document.add_path(template, path_item) }
        @document.set_components(@components)
        @document.set_security(@security)
        @document.set_tags(@tags)
        @document
      end

      def to_h
        build.to_h
      end
    end
  end
end
