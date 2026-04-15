# frozen_string_literal: true

module OpenapiRails
  class Error < StandardError; end

  class ConfigurationError < Error; end

  class InvalidDocumentError < Error
    attr_reader :validation_errors

    def initialize(validation_errors)
      @validation_errors = validation_errors
      super("Generated OpenAPI document is invalid: #{validation_errors.map { |e| e["error"] }.join(", ")}")
    end
  end

  class SchemaValidationError < Error
    attr_reader :validation_errors

    def initialize(validation_errors)
      @validation_errors = validation_errors
      super("Schema validation failed: #{validation_errors.map { |e| e["error"] }.join(", ")}")
    end
  end

  class RequestValidationError < Error
    attr_reader :validation_errors

    def initialize(validation_errors)
      @validation_errors = validation_errors
      super("Request validation failed: #{validation_errors.map { |e| e["error"] }.join(", ")}")
    end
  end

  class ResponseValidationError < Error
    attr_reader :validation_errors

    def initialize(validation_errors)
      @validation_errors = validation_errors
      super("Response validation failed: #{validation_errors.map { |e| e["error"] }.join(", ")}")
    end
  end

  class DuplicateComponentError < Error; end
end
