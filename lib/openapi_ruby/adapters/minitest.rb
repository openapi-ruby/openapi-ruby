# frozen_string_literal: true

require "openapi_ruby"

module OpenapiRuby
  module Adapters
    module Minitest
      module DSL
        def self.included(base)
          base.extend ClassMethods
          base.class_attribute :_openapi_contexts, default: []
          base.class_attribute :_openapi_schema_name, default: nil
        end

        module ClassMethods
          def openapi_schema(name)
            self._openapi_schema_name = name.to_sym
          end

          def api_path(template, &block)
            context = OpenapiRuby::DSL::Context.new(template, schema_name: _openapi_schema_name)
            context.instance_eval(&block) if block
            self._openapi_contexts = _openapi_contexts + [context]
            OpenapiRuby::DSL::MetadataStore.register(context)
            context
          end
        end

        def assert_api_response(method, expected_status, params: {}, headers: {}, body: nil, path_params: {}, &block)
          context = find_context_for(method, path_params)
          raise OpenapiRuby::Error, "No api_path defined for #{method.upcase} in #{self.class}" unless context

          operation = context.operations[method.to_s]
          raise OpenapiRuby::Error, "No #{method.upcase} operation defined" unless operation

          response_ctx = operation.responses[expected_status.to_s]
          raise OpenapiRuby::Error, "No response #{expected_status} defined for #{method.upcase}" unless response_ctx

          # Build the request path
          path = expand_path(context.path_template, params.merge(path_params))

          # Execute the request
          request_params = body || params.reject { |k, _| path_param_names(context).include?(k.to_s) }
          request_headers = headers.dup

          if body
            content_type = request_headers["Content-Type"] || context.operations[method.to_s]&.instance_variable_get(:@consumes_list)&.first

            if content_type&.include?("form-data") || content_type&.include?("x-www-form-urlencoded")
              request_params = body
              request_headers["Content-Type"] ||= content_type
            else
              request_params = body.is_a?(String) ? body : body.to_json
              request_headers["Content-Type"] ||= content_type || "application/json"
            end
          end

          send_args = {params: request_params}
          send_args[:headers] = request_headers if request_headers.any?

          send(method, path, **send_args)

          # Validate response
          if OpenapiRuby.configuration.validate_responses_in_tests
            assert_equal expected_status, response.status,
              "Expected status #{expected_status}, got #{response.status}"

            if response_ctx.schema_definition
              validator = Testing::ResponseValidator.new
              body_data = parse_response_body
              errors = validator.validate(
                response_body: body_data,
                status_code: response.status,
                response_context: response_ctx
              )
              assert errors.empty?, "Response validation failed:\n#{errors.join("\n")}"
            end
          end

          # Execute additional assertions
          instance_eval(&block) if block
        end

        def parsed_body
          parse_response_body
        end

        private

        def find_context_for(method, path_params)
          has_path_params = path_params.any?

          self.class._openapi_contexts.find do |ctx|
            next false unless ctx.operations.key?(method.to_s)

            if has_path_params
              # Pick the context that has path parameter placeholders
              ctx.path_template.include?("{")
            else
              # Pick the context without path parameter placeholders
              !ctx.path_template.include?("{")
            end
          end
        end

        def expand_path(template, params)
          template.gsub(/\{(\w+)\}/) do
            name = ::Regexp.last_match(1)
            value = params[name.to_sym] || params[name.to_s]
            value || "{#{name}}"
          end
        end

        def path_param_names(context)
          context.path_parameters.map { |p| p["name"] }
        end

        def parse_response_body
          return nil if response.body.empty?

          JSON.parse(response.body)
        rescue JSON::ParserError
          response.body
        end
      end

      def self.install!
        ::Minitest.after_run do
          OpenapiRuby::Generator::SchemaWriter.generate_all!
        rescue => e
          warn "[openapi_ruby] Schema generation failed: #{e.message}"
        end
      end
    end
  end
end
