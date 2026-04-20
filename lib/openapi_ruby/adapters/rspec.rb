# frozen_string_literal: true

require "openapi_ruby"
require "cgi"
require "uri"

module OpenapiRuby
  module Adapters
    module RSpec
      # Class-level DSL methods extended onto :openapi example groups.
      # All methods are inherited by nested describe/context/it_behaves_like blocks.
      # Data is stored in RSpec metadata which propagates to child groups.
      module ExampleGroupHelpers
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
            path_ctx.path_parameters.each { |p| op_context.parameter(p) }
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
            # Append query params to path when body is present
            if params.any?
              query_string = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
              path = "#{path}?#{query_string}"
            end
          else
            request_args = {params: params, headers: headers}
          end

          send(method.to_sym, path, **request_args)
        end

        def assert_openapi_response(metadata)
          response_ctx = find_in_metadata(metadata, :openapi_response)

          expected_status = response_ctx.status_code.to_i
          actual_status = response.status

          unless actual_status == expected_status
            raise "Response validation failed:\n" \
              "Expected status #{expected_status}, got #{actual_status}\n" \
              "Response body: #{response.body}"
          end
        end

        private

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
          return nil if response.body.empty?
          JSON.parse(response.body)
        rescue JSON::ParserError
          response.body
        end
      end

      def self.install!
        ::RSpec.configure do |config|
          config.extend ExampleGroupHelpers, type: :openapi
          config.include ExampleHelpers, type: :openapi

          if defined?(::RSpec::Rails)
            config.include ::RSpec::Rails::RequestExampleGroup, type: :openapi
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
