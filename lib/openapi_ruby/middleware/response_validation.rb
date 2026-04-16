# frozen_string_literal: true

module OpenapiRuby
  module Middleware
    class ResponseValidation
      def initialize(app, options = {})
        @app = app
        @resolver = options[:schema_resolver] || SchemaResolver.new(spec_path: options[:spec_path])
        @error_handler = options[:error_handler] || ErrorHandler.new
        @mode = options.fetch(:mode, OpenapiRuby.configuration.response_validation)
        @validate_success_only = options.fetch(:validate_success_only, true)
        @prefix = options[:prefix]
      end

      def call(env)
        return @app.call(env) if @mode == :disabled

        request = Rack::Request.new(env)

        # Skip if request doesn't match prefix
        if @prefix && !request.path_info.start_with?(@prefix)
          return @app.call(env)
        end

        status, headers, body = @app.call(env)

        # Skip validation for certain status codes
        return [status, headers, body] if skip_validation?(status)

        operation = env["openapi_ruby.operation"]
        unless operation
          request = Rack::Request.new(env)
          result = @resolver.find_operation(request.request_method, request.path_info)
          operation = result[:operation] if result
        end
        return [status, headers, body] unless operation

        # Find the response spec
        response_spec = operation.dig("responses", status.to_s) ||
          operation.dig("responses", "default")
        return [status, headers, body] unless response_spec

        # Validate the response body
        response_body = read_body(body)
        errors = validate_response(response_spec, response_body)

        if errors.any?
          if @mode == :warn_only
            env["openapi_ruby.response_errors"] = errors
            warn "[openapi_ruby] Response validation warnings: #{errors.join(", ")}"
          else
            return @error_handler.invalid_response(errors)
          end
        end

        [status, headers, body]
      end

      private

      def skip_validation?(status)
        return true if [204, 304].include?(status)
        return true if @validate_success_only && status >= 400

        false
      end

      def read_body(body)
        content = +""
        body.each { |chunk| content << chunk }
        body.rewind if body.respond_to?(:rewind)

        return nil if content.empty?

        JSON.parse(content)
      rescue JSON::ParserError
        content
      end

      def validate_response(response_spec, response_body)
        errors = []

        content_spec = response_spec.dig("content", "application/json")
        return errors unless content_spec && content_spec["schema"] && response_body

        schema_validator = build_schema_validator(content_spec["schema"])
        return errors unless schema_validator

        schema_validator.validate(response_body).each do |err|
          pointer = err["data_pointer"] || ""
          msg = err["error"] || err["type"] || "validation failed"
          location = pointer.empty? ? "response body" : "response body at #{pointer}"
          errors << "Invalid #{location}: #{msg}"
        end
        errors
      rescue => e
        [e.message]
      end

      def build_schema_validator(schema)
        if schema.is_a?(Hash) && schema["$ref"]
          @resolver.schemer.ref(schema["$ref"])
        else
          # For inline schemas that may contain nested $ref, resolve via document pointer
          pointer = find_schema_pointer(schema)
          if pointer
            @resolver.schemer.ref(pointer)
          else
            JSONSchemer.schema(schema)
          end
        end
      rescue
        nil
      end

      def find_schema_pointer(schema)
        # Walk the document to find the JSON pointer for this schema object
        document = @resolver.document
        document.fetch("paths", {}).each do |path, path_item|
          path_item.each do |method, operation|
            next unless operation.is_a?(Hash) && operation["responses"]

            operation["responses"].each do |status, resp|
              resp_schema = resp.dig("content", "application/json", "schema")
              if resp_schema.equal?(schema) || resp_schema == schema
                escaped_path = path.gsub("/", "~1")
                return "#/paths/#{escaped_path}/#{method}/responses/#{status}/content/application~1json/schema"
              end
            end
          end
        end
        nil
      end
    end
  end
end
