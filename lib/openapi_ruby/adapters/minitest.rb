# frozen_string_literal: true

require "openapi_ruby"
require_relative "context_resolution"
require "cgi"
require "uri"

module OpenapiRuby
  module Adapters
    module Minitest
      module DSL
        def self.included(base)
          base.extend ClassMethods
          base.class_attribute :_openapi_contexts, default: []
          base.class_attribute :_openapi_schema_name, default: nil

          install_rack_test!(base)
        end

        # On Rails the test class already inherits ActionDispatch's integration
        # helpers. Every other host drives requests through rack-test, and the
        # class defines `app` itself.
        def self.install_rack_test!(base)
          return if OpenapiRuby.rails_host?
          return if base.method_defined?(:last_response)

          require "rack/test"
          base.include ::Rack::Test::Methods
        rescue LoadError
          nil
        end

        module ClassMethods
          def openapi_schema(name)
            self._openapi_schema_name = name.to_sym
          end

          def api_path(template, &block)
            guard_single_api_path!(template)

            context = OpenapiRuby::DSL::Context.new(template, schema_name: _openapi_schema_name)
            context.instance_eval(&block) if block
            self._openapi_contexts = _openapi_contexts + [context]
            OpenapiRuby::DSL::MetadataStore.register(context)
            context
          end

          private def guard_single_api_path!(template)
            return unless OpenapiRuby.configuration.single_api_path_per_class

            existing = _openapi_contexts.first
            return if existing.nil?

            raise OpenapiRuby::MultipleApiPaths,
              "#{name || self} already declares api_path #{existing.path_template.inspect}; " \
              "declare #{template.inspect} in its own class."
          end
        end

        def assert_api_response(method, expected_status, params: {}, headers: {}, body: nil, path_params: {},
          api_path: nil, &block)
          context = find_context_for(method, path_params, params, expected_status, api_path)
          raise OpenapiRuby::Error, "No api_path defined for #{method.upcase} in #{self.class}" unless context

          operation = context.operations[method.to_s]
          raise OpenapiRuby::Error, "No #{method.upcase} operation defined" unless operation

          response_ctx = operation.responses[expected_status.to_s]
          raise OpenapiRuby::Error, "No response #{expected_status} defined for #{method.upcase}" unless response_ctx

          # Build the request path with base path from schema server URL
          base_path = resolve_base_path(context.schema_name)
          path = "#{base_path}#{expand_path(context.path_template, params.merge(path_params))}"

          # Resolve security scheme parameters
          security_params = resolve_security_params(operation, context.schema_name)
          security_params.each do |param|
            val = params[param[:name].to_sym] || params[param[:name]]
            next if val.nil?

            case param[:in].to_s
            when "header" then headers[param[:name]] = val
            when "query" then params[param[:name]] = val
            when "cookie" then headers["Cookie"] = "#{param[:name]}=#{val}"
            end
          end

          # Default Accept header for API requests
          headers["Accept"] ||= "application/json"

          # Build query params (exclude path params)
          query_params = params.reject { |k, _| path_param_names(context).include?(k.to_s) }

          # Execute the request
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
            # Append query params to path when body is present
            if query_params.any?
              query_string = query_params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
              path = "#{path}?#{query_string}"
            end
          else
            request_args = {params: query_params, headers: headers}
          end

          # Validate the request against the declared operation (skip for error responses,
          # since those tests intentionally send invalid data)
          if OpenapiRuby.configuration.test_request_validation && expected_status < 400
            document_hash = build_validation_document(context.schema_name)
            req_errors = Testing::RequestValidator.new(document_hash).validate(
              operation: operation,
              path_context: context,
              params: params,
              headers: headers,
              body: body,
              path_params: path_params
            )
            assert req_errors.empty?, "Request validation failed:\n#{req_errors.join("\n")}"
          end

          openapi_transport.dispatch(method, path, **request_args)

          # Validate response
          assert_equal expected_status, openapi_response.status,
            "Expected status #{expected_status}, got #{openapi_response.status}\nResponse body: #{openapi_response.body}"

          if response_ctx.schema_definition
            validator = Testing::ResponseValidator.new
            body_data = parse_response_body
            errors = validator.validate(
              response_body: body_data,
              status_code: openapi_response.status,
              response_context: response_ctx
            )
            assert errors.empty?, "Response validation failed:\n#{errors.join("\n")}"
          end

          # Execute additional assertions
          instance_eval(&block) if block
        end

        def parsed_body
          parse_response_body
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

        private

        def find_context_for(method, path_params, params, expected_status, api_path)
          OpenapiRuby::Adapters::ContextResolution.resolve(
            self.class._openapi_contexts, method, path_params,
            params: params, expected_status: expected_status, api_path: api_path, owner: self.class
          )
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

        def resolve_security_params(operation, schema_name)
          security_list = operation.instance_variable_get(:@security_list)
          return [] unless security_list

          config = OpenapiRuby.configuration
          schema_config = config.schemas[schema_name.to_sym] || config.schemas[schema_name.to_s]
          return [] unless schema_config

          security_schemes = schema_config.dig(:components, :securitySchemes) ||
            schema_config.dig("components", "securitySchemes") || {}

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
              {name: "Authorization", in: "header"}
            end
          end.uniq { |p| [p[:name], p[:in]] }
        end

        def build_validation_document(schema_name)
          return nil unless schema_name

          config = OpenapiRuby.configuration
          schema_config = config.schemas[schema_name.to_sym] || config.schemas[schema_name.to_s]
          return nil unless schema_config

          builder = OpenapiRuby::Core::DocumentBuilder.new(schema_config)
          OpenapiRuby::DSL::MetadataStore.contexts_for(schema_name).each do |ctx|
            builder.add_path(ctx.path_template, ctx.to_openapi)
          end
          scope = schema_config[:component_scope]
          loader = OpenapiRuby::Components::Loader.new(scope: scope)
          builder.merge_components(loader.to_openapi_hash)
          builder.build.data
        end

        def parse_response_body
          return nil if openapi_response.body.empty?

          JSON.parse(openapi_response.body)
        rescue JSON::ParserError
          openapi_response.body
        end
      end

      def self.install!
        # Schema writing is handled by the rake task (openapi_ruby:generate),
        # not by test runs. The rake task loads test files to register DSL
        # contexts, then calls SchemaWriter.generate_all! directly.
        # This prevents partial schema overwrites when running a subset of tests.
      end
    end
  end
end
