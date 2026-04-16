# frozen_string_literal: true

module OpenapiRuby
  module Core
    class Document
      MIN_OPENAPI_VERSION = "3.1.0"
      DEFAULT_OPENAPI_VERSION = "3.1.0"

      attr_reader :data

      def initialize(info: {}, servers: [], openapi_version: DEFAULT_OPENAPI_VERSION)
        validate_version!(openapi_version)
        @data = {
          "openapi" => openapi_version,
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
        result = @data.dup
        result["paths"] = result["paths"].sort.to_h if result["paths"]
        if result["components"]
          result["components"] = result["components"].transform_values { |v| v.sort.to_h }
        end
        result["tags"] = result["tags"].sort_by { |t| t["name"].to_s } if result["tags"]
        result
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
      rescue => e
        [{"error" => e.message}]
      end

      private

      def validate_version!(version)
        if Gem::Version.new(version) < Gem::Version.new(MIN_OPENAPI_VERSION)
          raise OpenapiRuby::ConfigurationError,
            "OpenAPI version must be >= #{MIN_OPENAPI_VERSION}, got #{version}"
        end
      end

      def normalize_info(info)
        result = info.transform_keys(&:to_s)
        result["title"] ||= ""
        result["version"] ||= "0.0.0"
        result
      end
    end
  end
end
