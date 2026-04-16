# frozen_string_literal: true

require "openapi_ruby"

module OpenapiRuby
  module Adapters
    module RSpec
      module ExampleGroupHelpers
        def path(template, &block)
          schema_name = metadata[:openapi_schema_name]
          context = DSL::Context.new(template, schema_name: schema_name)

          describe template do
            # Store context reference on the example group metadata
            metadata[:openapi_path_context] = context

            # Evaluate the block which defines operations via get/post/etc.
            # We need a proxy that captures DSL calls and maps them to RSpec describe blocks
            proxy = PathProxy.new(self, context)
            proxy.instance_eval(&block) if block

            # Register the context for spec generation
            DSL::MetadataStore.register(context)
          end
        end
      end

      class PathProxy
        def initialize(example_group, context)
          @example_group = example_group
          @context = context
        end

        def parameter(attributes = {})
          @context.parameter(attributes)
        end

        DSL::Context::HTTP_METHODS.each do |method|
          define_method(method) do |summary = nil, &block|
            op_context = DSL::OperationContext.new(method, summary)
            # Copy path-level parameters
            @context.path_parameters.each { |p| op_context.parameter(p) }
            @context.operations[method.to_s] = op_context

            @example_group.describe "#{method.to_s.upcase} #{@context.path_template}" do
              # Evaluate operation-level DSL
              op_proxy = OperationProxy.new(self, op_context, @context)
              op_proxy.instance_eval(&block) if block
            end
          end
        end

        private

        # Forward missing methods to the example group for non-DSL calls
        def method_missing(name, ...)
          if @example_group.respond_to?(name)
            @example_group.send(name, ...)
          else
            super
          end
        end

        def respond_to_missing?(name, include_private = false)
          @example_group.respond_to?(name, include_private) || super
        end
      end

      class OperationProxy
        def initialize(example_group, operation_context, path_context)
          @example_group = example_group
          @operation = operation_context
          @path_context = path_context
        end

        %i[tags operationId description deprecated consumes produces security
          parameter request_body request_body_example].each do |method|
          define_method(method) do |*args, **kwargs, &block|
            if kwargs.empty?
              @operation.send(method, *args, &block)
            else
              @operation.send(method, *args, **kwargs, &block)
            end
          end
        end

        def response(status_code, description, &block)
          response_ctx = @operation.response(status_code, description)
          operation = @operation

          @example_group.context "response #{status_code} #{description}" do
            metadata[:openapi_operation] = operation
            metadata[:openapi_response] = response_ctx

            # Evaluate response-level DSL
            resp_proxy = ResponseProxy.new(self, response_ctx)
            resp_proxy.instance_eval(&block) if block
          end
        end

        private

        def method_missing(name, ...)
          if @example_group.respond_to?(name)
            @example_group.send(name, ...)
          else
            super
          end
        end

        def respond_to_missing?(name, include_private = false)
          @example_group.respond_to?(name, include_private) || super
        end
      end

      class ResponseProxy
        def initialize(example_group, response_context)
          @example_group = example_group
          @response = response_context
        end

        def schema(definition)
          @response.schema(definition)
        end

        def header(name, attributes = {})
          @response.header(name, attributes)
        end

        def example(content_type, **)
          @response.example(content_type, **)
        end

        def produces(*content_types)
          @response.produces(*content_types)
        end

        def run_test!(description = nil, &block)
          response_ctx = @response
          @example_group.it(description || "returns #{response_ctx.status_code}") do |example|
            example_metadata = example.metadata

            # Resolve path parameters from let variables
            path = resolve_path(example_metadata)
            operation = find_operation(example_metadata)

            # Build params and headers from let variables
            params = resolve_let(:request_params) || {}
            headers = resolve_let(:request_headers) || {}
            body = resolve_let(:request_body)

            # Merge individual parameter let values
            operation&.parameters&.each do |param|
              name = param["name"]
              val = resolve_let(name.to_sym)
              next unless val

              case param["in"]
              when "query"
                params[name] = val
              when "header"
                headers[name] = val
              when "path"
                # Already handled in resolve_path
              end
            end

            # Execute the request
            method = operation&.verb || example_metadata[:openapi_operation]&.verb || "get"
            send_args = {params: body || params}
            send_args[:headers] = headers if headers.any?

            if body
              content_type = headers["Content-Type"] || operation&.instance_variable_get(:@consumes_list)&.first

              if content_type&.include?("form-data") || content_type&.include?("x-www-form-urlencoded")
                send_args[:params] = body
                send_args[:headers] = (headers || {}).merge("Content-Type" => content_type)
              else
                send_args[:params] = body.is_a?(String) ? body : body.to_json
                send_args[:headers] = (headers || {}).merge("Content-Type" => content_type || "application/json")
              end
            end

            send(method.to_sym, path, **send_args)

            # Validate response
            if OpenapiRuby.configuration.validate_responses_in_tests && response_ctx.schema_definition
              validator = Testing::ResponseValidator.new
              errors = validator.validate(
                response_body: parsed_response_body,
                status_code: response.status,
                response_context: response_ctx
              )
              expect(errors).to be_empty, "Response validation failed:\n#{errors.join("\n")}"
            else
              expect(response.status).to eq(response_ctx.status_code.to_i)
            end

            # Execute additional assertions
            instance_eval(&block) if block
          end
        end

        # Forward let/before/after/subject to RSpec
        def method_missing(name, ...)
          if @example_group.respond_to?(name)
            @example_group.send(name, ...)
          else
            super
          end
        end

        def respond_to_missing?(name, include_private = false)
          @example_group.respond_to?(name, include_private) || super
        end
      end

      # Helper methods mixed into RSpec examples
      module ExampleHelpers
        private

        def resolve_path(metadata)
          path_ctx = find_path_context(metadata)
          template = path_ctx&.path_template || ""
          find_operation(metadata)

          # Substitute {param} placeholders with let values
          template.gsub(/\{(\w+)\}/) do
            name = ::Regexp.last_match(1)
            val = resolve_let(name.to_sym)
            val || "{#{name}}"
          end
        end

        def find_path_context(metadata)
          meta = metadata
          while meta
            return meta[:openapi_path_context] if meta[:openapi_path_context]

            meta = meta[:parent_example_group]
          end
          nil
        end

        def find_operation(metadata)
          meta = metadata
          while meta
            return meta[:openapi_operation] if meta[:openapi_operation]

            meta = meta[:parent_example_group]
          end
          nil
        end

        def resolve_let(name)
          send(name)
        rescue NameError
          nil
        end

        def parsed_response_body
          return nil if response.body.empty?

          JSON.parse(response.body)
        rescue JSON::ParserError
          response.body
        end

        def operation_context_from_parent
          meta = self.class.metadata
          while meta
            return meta[:openapi_operation] if meta[:openapi_operation]

            meta = meta[:parent_example_group]
          end
          nil
        end
      end

      def self.install!
        ::RSpec.configure do |config|
          config.extend ExampleGroupHelpers, type: :openapi
          config.include ExampleHelpers, type: :openapi

          # Make type: :openapi behave like request specs (includes integration test methods)
          if defined?(::RSpec::Rails)
            config.include ::RSpec::Rails::RequestExampleGroup, type: :openapi
          end

          config.after(:suite) do
            OpenapiRuby::Generator::SchemaWriter.generate_all!
          rescue => e
            warn "[openapi_ruby] Schema generation failed: #{e.message}"
          end
        end
      end
    end
  end
end
