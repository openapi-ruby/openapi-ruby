# frozen_string_literal: true

require "openapi_ruby"
require_relative "context_resolution"
require "cgi"
require "uri"

module OpenapiRuby
  module Adapters
    module RSpec
      # Class-level DSL methods extended onto :openapi example groups.
      # All methods are inherited by nested describe/context/it_behaves_like blocks.
      # Data is stored in RSpec metadata which propagates to child groups.
      module ExampleGroupHelpers
        def openapi_schema(name)
          metadata[:openapi_schema_name] = name.to_sym
        end

        # Minitest-style DSL: define the schema at the top of the spec file,
        # then write normal RSpec examples underneath using assert_api_response.
        def api_path(template, &block)
          schema_name = metadata[:openapi_schema_name]
          context = DSL::Context.new(template, schema_name: schema_name)
          context.instance_eval(&block) if block
          # Replace rather than push: RSpec copies parent metadata into child
          # groups by reference, so mutating the array in place would leak this
          # declaration back up to the parent and sideways to its siblings.
          # Building a new one is what makes a nested describe an actual scope.
          metadata[:openapi_api_contexts] = (metadata[:openapi_api_contexts] || []) + [context]
          DSL::MetadataStore.register(context)
          context
        end

        def path(template, &block)
          schema_name = metadata[:openapi_schema_name]
          context = DSL::Context.new(template, schema_name: schema_name)

          describe template do
            metadata[:openapi_path_context] = context
            instance_eval(&block) if block
            DSL::MetadataStore.register(context)
          end
        end

        DSL::Context::HTTP_METHODS.each do |method|
          define_method(method) do |summary = nil, &block|
            path_ctx = metadata[:openapi_path_context]
            op_context = DSL::OperationContext.new(method, summary)
            path_ctx.operations[method.to_s] = op_context

            describe "#{method.to_s.upcase} #{path_ctx.path_template}" do
              metadata[:openapi_operation] = op_context
              instance_eval(&block) if block
            end
          end
        end

        def parameter(attributes = {})
          if metadata[:openapi_operation]
            metadata[:openapi_operation].parameter(attributes)
          elsif metadata[:openapi_path_context]
            metadata[:openapi_path_context].parameter(attributes)
          end
        end

        %i[tags operationId deprecated security].each do |attr_name|
          define_method(attr_name) do |value|
            metadata[:openapi_operation]&.send(attr_name, value)
          end
        end

        def description(value = nil)
          return super() if value.nil?
          metadata[:openapi_operation]&.description(value)
        end

        def consumes(*content_types)
          metadata[:openapi_operation]&.consumes(*content_types)
        end

        def produces(*content_types)
          metadata[:openapi_operation]&.produces(*content_types)
        end

        def request_body(attributes = {})
          metadata[:openapi_operation]&.request_body(attributes)
        end

        def request_body_example(**kwargs)
          metadata[:openapi_operation]&.request_body_example(**kwargs)
        end

        def response(status_code, description, hidden: false, &block)
          operation = metadata[:openapi_operation]
          response_ctx = operation.response(status_code, description, hidden: hidden)

          context "response #{status_code} #{description}" do
            metadata[:openapi_response] = response_ctx
            instance_eval(&block) if block
          end
        end

        def schema(definition)
          metadata[:openapi_response]&.schema(definition)
        end

        def header(name, attributes = {})
          metadata[:openapi_response]&.header(name, attributes)
        end

        def run_test!(description = nil, &block)
          response_ctx = metadata[:openapi_response]

          before do |example|
            submit_openapi_request(example.metadata)
          end

          it(description || "returns #{response_ctx.status_code}") do |example|
            assert_openapi_response(example.metadata)
            instance_eval(&block) if block
          end
        end
      end

      # Instance-level helper methods mixed into RSpec examples
      module ExampleHelpers
        # Minitest-style assertion: looks up the api_path context, makes the
        # request, validates the response status + body, then yields to the
        # block for additional expectations.
        def assert_api_response(method, expected_status, params: {}, headers: {}, body: nil, path_params: {},
          api_path: nil, &block)
          meta = ::RSpec.current_example.metadata
          context = find_api_context_for(meta, method, path_params, params, expected_status, api_path)
          raise OpenapiRuby::Error, "No api_path defined for #{method.upcase} in this example group" unless context

          operation = context.operations[method.to_s]
          raise OpenapiRuby::Error, "No #{method.upcase} operation defined" unless operation

          response_ctx = operation.responses[expected_status.to_s]
          raise OpenapiRuby::Error, "No response #{expected_status} defined for #{method.upcase}" unless response_ctx

          base_path = resolve_base_path(context.schema_name)
          path = "#{base_path}#{expand_path(context.path_template, params.merge(path_params))}"

          # Resolve security scheme parameters
          resolve_security_params(operation, meta).each do |param|
            val = params[param[:name].to_sym] || params[param[:name]]
            next if val.nil?

            case param[:in].to_s
            when "header" then headers[param[:name]] = val
            when "query" then params[param[:name]] = val
            when "cookie" then headers["Cookie"] = "#{param[:name]}=#{val}"
            end
          end

          headers["Accept"] ||= "application/json"

          path_param_names = context.path_parameters.map { |p| p["name"] }
          query_params = params.reject { |k, _| path_param_names.include?(k.to_s) }

          if body
            content_type = operation.request_body_definition&.dig("content")&.keys&.first || "application/json"
            request_args = if content_type.include?("form-data") || content_type.include?("x-www-form-urlencoded")
              {params: body, headers: headers}
            else
              {
                params: body.is_a?(String) ? body : body.to_json,
                headers: headers.merge("Content-Type" => content_type)
              }
            end
          else
            request_args = {headers: headers}
          end

          if query_params.any?
            path = "#{path}?#{Rack::Utils.build_nested_query(query_params)}"
          end

          # Validate the request against the declared operation (skip for error responses,
          # since those tests intentionally send invalid data)
          if OpenapiRuby.configuration.test_request_validation && expected_status < 400
            document_hash = OpenapiRuby::Adapters::RSpec.validation_document_for(context.schema_name)
            req_errors = Testing::RequestValidator.new(document_hash).validate(
              operation: operation,
              path_context: context,
              params: params,
              headers: headers,
              body: body,
              path_params: path_params
            )
            raise "Request validation failed:\n#{req_errors.join("\n")}" unless req_errors.empty?
          end

          openapi_transport.dispatch(method, path, **request_args)

          unless openapi_response.status == expected_status
            raise "Expected status #{expected_status}, got #{openapi_response.status}\nResponse body: #{openapi_response.body}"
          end

          if response_ctx.schema_definition
            validator = Testing::ResponseValidator.new(
              OpenapiRuby::Adapters::RSpec.validation_document_for(context.schema_name)
            )
            errors = validator.validate(
              response_body: parsed_response_body,
              status_code: openapi_response.status,
              response_context: response_ctx
            )
            unless errors.empty?
              raise "Response body validation failed:\n#{errors.join("\n")}\nResponse body: #{openapi_response.body}"
            end
          end

          instance_eval(&block) if block
        end

        def parsed_body
          parsed_response_body
        end

        # The seam between the DSL and the host's request API. Public so specs
        # that drive requests themselves (rate limiting, pagination loops) can
        # reach the same dispatcher and response the assertions use.
        def openapi_transport
          @openapi_transport ||= Testing::Transport.for(self)
        end

        def openapi_response
          openapi_transport.response
        end

        # submit_openapi_request is public so specs can call it directly
        # (e.g., for rate limiting tests that need multiple requests)
        def submit_openapi_request(metadata)
          path = resolve_path(metadata)
          operation = find_in_metadata(metadata, :openapi_operation)

          params = resolve_let(:request_params) || {}
          headers = resolve_let(:request_headers) || {}
          body = resolve_let(:request_body)

          # Merge individual parameter let values
          operation&.parameters&.each do |param|
            name = param["name"]
            next unless name
            val = resolve_let(name.to_sym)
            next if val.nil?

            case param["in"]
            when "query" then params[name] = val
            when "header" then headers[name] = val
            end
          end

          # Resolve security scheme parameters from let variables
          resolve_security_params(operation, metadata).each do |param|
            val = resolve_let(param[:name].to_sym)
            next unless val

            case param[:in].to_s
            when "header" then headers[param[:name]] = val
            when "query" then params[param[:name]] = val
            when "cookie" then headers["Cookie"] = "#{param[:name]}=#{val}"
            end
          end

          method = operation&.verb || "get"
          # Accept header: use let(:Accept) if defined, otherwise default to JSON
          accept = resolve_let(:Accept)
          headers["Accept"] = accept || "application/json"

          # Always append query params to the URL so the middleware sees them
          # (Rails sends params as request body for non-GET methods).
          if params.any?
            path = "#{path}?#{Rack::Utils.build_nested_query(params)}"
          end

          if body
            content_type = operation&.request_body_definition&.dig("content")&.keys&.first || "application/json"
            request_args = if content_type.include?("form-data") || content_type.include?("x-www-form-urlencoded")
              {params: body, headers: headers}
            else
              {
                params: body.is_a?(String) ? body : body.to_json,
                headers: headers.merge("Content-Type" => content_type)
              }
            end
          else
            request_args = {headers: headers}
          end

          # Validate the request against the declared operation (skip for error responses,
          # since those tests intentionally send invalid data)
          response_ctx = find_in_metadata(metadata, :openapi_response)
          expected_status = response_ctx&.status_code.to_i
          if OpenapiRuby.configuration.test_request_validation && operation && expected_status < 400
            path_ctx = find_in_metadata(metadata, :openapi_path_context)
            schema_name = find_in_metadata(metadata, :openapi_schema_name)

            # Collect resolved path param values for validation
            path_param_values = {}
            (path_ctx&.path_parameters || []).each do |param|
              name = param["name"]
              next unless name
              val = resolve_let(name.to_sym)
              path_param_values[name] = val if val
            end

            document_hash = OpenapiRuby::Adapters::RSpec.validation_document_for(schema_name)
            req_errors = Testing::RequestValidator.new(document_hash).validate(
              operation: operation,
              path_context: path_ctx,
              params: params,
              headers: headers,
              body: body,
              path_params: path_param_values
            )
            raise "Request validation failed:\n#{req_errors.join("\n")}" unless req_errors.empty?
          end

          openapi_transport.dispatch(method, path, **request_args)
        end

        def assert_openapi_response(metadata)
          response_ctx = find_in_metadata(metadata, :openapi_response)

          expected_status = response_ctx.status_code.to_i
          actual_status = openapi_response.status

          unless actual_status == expected_status
            raise "Response validation failed:\n" \
              "Expected status #{expected_status}, got #{actual_status}\n" \
              "Response body: #{openapi_response.body}"
          end

          if response_ctx.schema_definition
            schema_name = find_in_metadata(metadata, :openapi_schema_name)
            validator = Testing::ResponseValidator.new(OpenapiRuby::Adapters::RSpec.validation_document_for(schema_name))
            errors = validator.validate(
              response_body: parsed_response_body,
              status_code: openapi_response.status,
              response_context: response_ctx
            )
            unless errors.empty?
              raise "Response body validation failed:\n#{errors.join("\n")}\nResponse body: #{openapi_response.body}"
            end
          end
        end

        private

        def find_api_context_for(metadata, method, path_params, params, expected_status, api_path)
          contexts = find_in_metadata(metadata, :openapi_api_contexts) || []

          OpenapiRuby::Adapters::ContextResolution.resolve(
            contexts, method, path_params,
            params: params, expected_status: expected_status, api_path: api_path,
            owner: metadata[:full_description] || "this example group"
          )
        end

        def expand_path(template, params)
          template.gsub(/\{(\w+)\}/) do
            name = ::Regexp.last_match(1)
            value = params[name.to_sym] || params[name.to_s]
            value || "{#{name}}"
          end
        end

        def resolve_path(metadata)
          path_ctx = find_in_metadata(metadata, :openapi_path_context)
          template = path_ctx&.path_template || ""

          base_path = resolve_base_path(path_ctx&.schema_name)
          full_path = "#{base_path}#{template}"

          full_path.gsub(/\{(\w+)\}/) do
            name = ::Regexp.last_match(1)
            resolve_let(name.to_sym) || "{#{name}}"
          end
        end

        def find_in_metadata(metadata, key)
          meta = metadata
          while meta
            return meta[key] if meta[key]
            meta = meta[:parent_example_group]
          end
          nil
        end

        def resolve_base_path(schema_name)
          return "" unless schema_name

          config = OpenapiRuby.configuration
          schema_config = config.schemas[schema_name.to_sym] || config.schemas[schema_name.to_s]
          return "" unless schema_config

          server_url = schema_config.dig(:servers, 0, :url) || schema_config.dig("servers", 0, "url")
          return "" unless server_url

          URI.parse(server_url).path.chomp("/")
        rescue URI::InvalidURIError
          ""
        end

        def resolve_security_params(operation, metadata)
          security_list = operation&.instance_variable_get(:@security_list)
          return [] unless security_list

          schema_name = find_in_metadata(metadata, :openapi_schema_name)
          return [] unless schema_name

          config = OpenapiRuby.configuration
          schema_config = config.schemas[schema_name.to_sym] || config.schemas[schema_name.to_s]
          return [] unless schema_config

          security_schemes = schema_config.dig(:components, :securitySchemes) ||
            schema_config.dig("components", "securitySchemes") || {}

          # Also check registered components using the schema's configured scope
          if security_schemes.empty?
            scope = schema_config[:component_scope] || schema_config["component_scope"]
            loader = Components::Loader.new(scope: scope&.to_sym)
            security_schemes = loader.security_schemes
          end

          scheme_names = security_list.flat_map { |s| s.is_a?(Hash) ? s.keys.map(&:to_s) : [] }

          scheme_names.filter_map do |name|
            scheme = security_schemes[name] || security_schemes[name.to_sym]
            next unless scheme

            type = scheme[:type] || scheme["type"]
            if type.to_s == "apiKey"
              {name: (scheme[:name] || scheme["name"]).to_s, in: (scheme[:in] || scheme["in"]).to_s}
            else
              # OAuth2, http bearer, etc. → Authorization header
              {name: "Authorization", in: "header"}
            end
          end.uniq { |p| [p[:name], p[:in]] }
        end

        def resolve_let(name)
          send(name)
        rescue NameError
          nil
        end

        def parsed_response_body
          return nil if openapi_response.body.empty?
          JSON.parse(openapi_response.body)
        rescue JSON::ParserError
          openapi_response.body
        end
      end

      # Build the OpenAPI document hash for a given schema name and cache it.
      # Used by response body validation so $ref schemas can be resolved.
      def self.validation_document_for(schema_name)
        return nil unless schema_name

        key = schema_name.to_sym
        @validation_documents ||= {}
        @validation_documents[key] ||= begin
          config = OpenapiRuby.configuration
          schema_config = config.schemas[key] || config.schemas[schema_name.to_s]
          return nil unless schema_config

          builder = OpenapiRuby::Core::DocumentBuilder.new(schema_config)
          OpenapiRuby::DSL::MetadataStore.contexts_for(schema_name).each do |context|
            builder.add_path(context.path_template, context.to_openapi)
          end
          scope = schema_config[:component_scope]
          loader = OpenapiRuby::Components::Loader.new(scope: scope)
          builder.merge_components(loader.to_openapi_hash)
          builder.build.data
        end
      end

      # Every host but Rails drives requests through rack-test. Hanami also
      # gets a default `app`; elsewhere (Sinatra, Roda, bare Rack) there is no
      # convention for which app is under test, so the suite defines it.
      def self.install_rack_test!(config, app_module: nil)
        require "rack/test"

        config.include ::Rack::Test::Methods, type: :openapi
        config.include app_module, type: :openapi if app_module
      rescue LoadError
        # No rack-test in the bundle. Testing::Transport raises with setup
        # instructions if a spec then tries to issue a request.
        nil
      end

      def self.install!
        ::RSpec.configure do |config|
          config.extend ExampleGroupHelpers, type: :openapi
          config.include ExampleHelpers, type: :openapi

          if defined?(::RSpec::Rails)
            config.include ::RSpec::Rails::RequestExampleGroup, type: :openapi
          elsif OpenapiRuby.hanami_host?
            require "openapi_ruby/hanami"
            OpenapiRuby::Hanami.install_rspec!(config)
          else
            install_rack_test!(config)
          end

          # Schema writing is handled by the rake task (openapi_ruby:generate),
          # not by test runs. The rake task loads spec files to register DSL
          # contexts, then calls SchemaWriter.generate_all! directly.
          # This prevents partial schema overwrites when running a subset of specs.
        end
      end
    end
  end
end
