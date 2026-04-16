# frozen_string_literal: true

module OpenapiRuby
  module Middleware
    class RequestValidation
      def initialize(app, options = {})
        @app = app
        @resolver = options[:schema_resolver] || SchemaResolver.new(spec_path: options[:spec_path])
        @strict = options.fetch(:strict, false)
        @coerce = options.fetch(:coerce, OpenapiRuby.configuration.coerce_params)
        @error_handler = options[:error_handler] || ErrorHandler.new
        @mode = options.fetch(:mode, OpenapiRuby.configuration.request_validation)
        @prefix = options[:prefix]
      end

      def call(env)
        return @app.call(env) if @mode == :disabled

        request = Rack::Request.new(env)

        # Skip if request doesn't match prefix
        if @prefix && !request.path_info.start_with?(@prefix)
          return @app.call(env)
        end

        # Strip prefix for path matching
        match_path = @prefix ? request.path_info.sub(@prefix, "") : request.path_info
        result = @resolver.find_operation(request.request_method, match_path)

        if result.nil?
          return strict? ? @error_handler.not_found(request.path_info) : @app.call(env)
        end

        operation = result[:operation]
        path_params = result[:path_params]
        parameters = operation.fetch("parameters", [])

        # Coerce params if enabled
        if @coerce
          env["rack.request.query_hash"] = Coercion.coerce_params(
            request.GET, parameters.select { |p| p["in"] == "query" }
          )
        end

        # Store operation info for downstream use
        env["openapi_ruby.operation"] = operation
        env["openapi_ruby.path_params"] = path_params
        env["openapi_ruby.path_template"] = result[:template]

        # Validate request
        errors = validate_request(request, operation, path_params)

        if errors.any?
          return @error_handler.invalid_request(errors) unless @mode == :warn_only

          env["openapi_ruby.request_errors"] = errors
          warn "[openapi_ruby] Request validation warnings: #{errors.join(", ")}"
        end

        @app.call(env)
      end

      private

      def strict?
        return @strict if @strict

        # Check per-schema strict_mode from configuration
        OpenapiRuby.configuration.schemas.any? { |_name, config| config[:strict_mode] }
      end

      def validate_request(request, operation, path_params)
        errors = []
        parameters = operation.fetch("parameters", [])

        # Validate each parameter (presence + type)
        parameters.each do |param|
          value = extract_param_value(request, param, path_params)

          if value.nil?
            errors << "Missing required #{param["in"]} parameter: #{param["name"]}" if param["required"]
            next
          end

          # Validate parameter value against schema
          if param["schema"]
            param_errors = validate_value(value, param["schema"], "#{param["in"]} parameter '#{param["name"]}'")
            errors.concat(param_errors)
          end
        end

        # Validate request body
        errors.concat(validate_request_body(request, operation))

        errors
      end

      def extract_param_value(request, param, path_params)
        case param["in"]
        when "query" then request.GET[param["name"]]
        when "header" then request.get_header("HTTP_#{param["name"].upcase.tr("-", "_")}")
        when "path" then path_params[param["name"]]
        end
      end

      def validate_request_body(request, operation)
        errors = []
        rb_spec = operation["requestBody"]
        return errors unless rb_spec

        content_type = request.content_type&.split(";")&.first
        body_content = read_request_body(request)

        if rb_spec["required"] && body_content.nil?
          errors << "Request body is required"
          return errors
        end

        return errors unless body_content && rb_spec["content"]

        if content_type && !rb_spec["content"].key?(content_type)
          errors << "Unsupported content type: #{content_type}"
          return errors
        end

        # Validate body against schema
        media_type = content_type || rb_spec["content"].keys.first
        schema = rb_spec.dig("content", media_type, "schema")
        return errors unless schema

        body_data = parse_body(body_content, media_type)
        return errors unless body_data

        validate_against_document(body_data, schema, "request body", errors)
        errors
      end

      def validate_value(value, schema, context)
        errors = []
        # Coerce string values for validation based on schema type
        coerced = coerce_for_validation(value, schema)
        schemer = JSONSchemer.schema(schema)
        schemer.validate(coerced).each do |err|
          msg = err["error"] || err["type"] || "validation failed"
          errors << "Invalid #{context}: #{msg}"
        end
        errors
      rescue => e
        ["Invalid #{context}: #{e.message}"]
      end

      def validate_against_document(data, schema, context, errors)
        schema_validator = resolve_schema(schema)
        schema_validator.validate(data).each do |err|
          pointer = err["data_pointer"] || ""
          msg = err["error"] || err["type"] || "validation failed"
          location = pointer.empty? ? context : "#{context} at #{pointer}"
          errors << "Invalid #{location}: #{msg}"
        end
      rescue => e
        errors << "Invalid #{context}: #{e.message}"
      end

      def resolve_schema(schema)
        if schema.is_a?(Hash) && schema["$ref"]
          @resolver.schemer.ref(schema["$ref"])
        else
          JSONSchemer.schema(schema)
        end
      end

      def coerce_for_validation(value, schema)
        return value unless value.is_a?(String)

        case schema["type"]
        when "integer"
          Integer(value)
        when "number"
          Float(value)
        when "boolean"
          case value.downcase
          when "true", "1" then true
          when "false", "0" then false
          else value
          end
        else
          value
        end
      rescue ArgumentError, TypeError
        value
      end

      def read_request_body(request)
        return nil unless request.body

        content = request.body.read
        request.body.rewind
        content.empty? ? nil : content
      end

      def parse_body(content, media_type)
        return nil unless content

        if media_type&.include?("json")
          JSON.parse(content)
        elsif media_type&.include?("x-www-form-urlencoded")
          Rack::Utils.parse_nested_query(content)
        elsif media_type&.include?("form-data")
          # Multipart form data is already parsed by Rack into params
          nil
        else
          content
        end
      rescue JSON::ParserError
        nil
      end
    end
  end
end
