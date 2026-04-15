# frozen_string_literal: true

module OpenapiRails
  module Core
    class Document
      OPENAPI_VERSION = "3.1.0"

      attr_reader :data

      def initialize(info: {}, servers: [])
        @data = {
          "openapi" => OPENAPI_VERSION,
          "info" => normalize_info(info),
          "paths" => {}
        }
        @data["servers"] = servers.map { |s| s.transform_keys(&:to_s) } if servers.any?
      end

      def add_path(template, path_item)
        @data["paths"][template] ||= {}
        @data["paths"][template].merge!(path_item)
      end

      def set_components(components)
        @data["components"] = components if components.any?
      end

      def set_security(security)
        @data["security"] = security if security.any?
      end

      def set_tags(tags)
        @data["tags"] = tags if tags.any?
      end

      def to_h
        @data
      end

      def to_json(*_args)
        JSON.pretty_generate(@data)
      end

      def to_yaml
        require "yaml"
        @data.to_yaml
      end

      def valid?
        validate.empty?
      end

      def validate
        schemer = JSONSchemer.openapi(@data)
        schemer.validate.to_a
      rescue StandardError => e
        [{ "error" => e.message }]
      end

      private

      def normalize_info(info)
        result = info.transform_keys(&:to_s)
        result["title"] ||= ""
        result["version"] ||= "0.0.0"
        result
      end
    end
  end
end
