# frozen_string_literal: true

module OpenapiRuby
  module Testing
    class RequestValidator
      def initialize(document_hash = nil)
        @document_hash = document_hash
      end

      def validate(operation:, path_context: nil, params: {}, headers: {}, body: nil, path_params: {})
        errors = []

        # Collect all parameters (path-level + operation-level)
        all_parameters = (path_context&.path_parameters || []) + (operation.parameters || [])

        # Validate each declared parameter
        all_parameters.each do |param|
          name = param["name"]
          next unless name

          value = extract_param_value(param, params, headers, path_params)

          if value.nil?
            errors << "Missing required #{param["in"]} parameter: #{name}" if param["required"]
            next
          end

          if param["schema"]
            param_errors = validate_value(value, param["schema"], "#{param["in"]} parameter '#{name}'")
            errors.concat(param_errors)
          end
        end

        # Validate request body
        errors.concat(validate_request_body(operation, body))

        errors
      end

      private

      # A value may arrive under the declared name or the camelized wire name,
      # depending on whether the caller wrote it or an adapter already renamed
      # it for the request. Both spellings resolve.
      def extract_param_value(param, params, headers, path_params)
        names = ParameterNames.lookup_names(param)

        case param["in"]
        when "query"
          fetch_any(params, names)
        when "path"
          fetch_any(path_params, names)
        when "header"
          fetch_any(headers, names.flat_map { |name| [name, name.downcase] })
        end
      end

      def fetch_any(store, names)
        names.each do |name|
          value = store[name.to_sym] || store[name.to_s]
          return value if value
        end
        nil
      end

      def validate_request_body(operation, body)
        errors = []
        rb_spec = operation.request_body_definition
        return errors unless rb_spec

        if rb_spec["required"] && body.nil?
          errors << "Request body is required"
          return errors
        end

        return errors unless body && rb_spec["content"]

        media_type = rb_spec["content"].keys.first
        schema = rb_spec.dig("content", media_type, "schema")
        return errors unless schema

        validate_against_schema(body, schema, "request body", errors)
        errors
      end

      def validate_value(value, schema, context)
        coerced = coerce_for_validation(value, schema)
        schema_validator = resolve_schema(schema)
        return [] unless schema_validator

        schema_validator.validate(coerced).map do |err|
          "Invalid #{context}: #{format_error(err)}"
        end
      rescue => e
        ["Invalid #{context}: #{e.message}"]
      end

      def validate_against_schema(data, schema, context, errors)
        schema_validator = resolve_schema(schema)
        return unless schema_validator

        schema_validator.validate(data).each do |err|
          pointer = err["data_pointer"] || ""
          msg = format_error(err)
          location = pointer.empty? ? context : "#{context} at #{pointer}"
          errors << "Invalid #{location}: #{msg}"
        end
      rescue => e
        errors << "Invalid #{context}: #{e.message}"
      end

      def resolve_schema(schema)
        if schema.is_a?(Hash) && schema["$ref"] && @document_hash
          JSONSchemer.openapi(@document_hash).ref(schema["$ref"])
        elsif contains_ref?(schema)
          nil # Cannot validate $ref without document
        else
          JSONSchemer.schema(schema)
        end
      rescue
        nil
      end

      def coerce_for_validation(value, schema)
        return value unless value.is_a?(String)

        type = schema.is_a?(Hash) ? schema["type"] : nil
        case type
        when "integer" then Integer(value)
        when "number" then Float(value)
        when "boolean"
          case value.downcase
          when "true", "1" then true
          when "false", "0" then false
          else value
          end
        else value
        end
      rescue ArgumentError, TypeError
        value
      end

      def contains_ref?(value)
        case value
        when Hash
          return true if value.key?("$ref")
          value.values.any? { |v| contains_ref?(v) }
        when Array
          value.any? { |v| contains_ref?(v) }
        else
          false
        end
      end

      def format_error(error)
        if error.is_a?(Hash)
          error["error"] || error["type"] || "validation failed"
        else
          error.to_s
        end
      end
    end
  end
end
