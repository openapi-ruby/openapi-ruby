# frozen_string_literal: true

require "spec_helper"
require "openapi_ruby/adapters/rspec"

RSpec.describe OpenapiRuby::Adapters::RSpec::ExampleHelpers do
  describe "#submit_openapi_request" do
    it "skips $ref parameters that have no name" do
      # Build a minimal operation with a $ref parameter (no "name" key)
      operation = OpenapiRuby::DSL::OperationContext.new(:get, "Test")
      operation.parameter("$ref": "#/components/parameters/PageParam")
      operation.parameter(name: :page, in: :query, schema: {type: :integer})

      # Verify the $ref param has no "name" key
      ref_param = operation.parameters.find { |p| p["$ref"] }
      expect(ref_param["name"]).to be_nil

      # Build a fake test instance that includes ExampleHelpers
      helper_class = Class.new do
        include OpenapiRuby::Adapters::RSpec::ExampleHelpers

        def get(path, **args)
          @last_request = {path: path, **args}
        end

        attr_reader :last_request
      end
      helper = helper_class.new

      # Stub out dependencies so we can test only the parameter loop
      path_ctx = instance_double(
        OpenapiRuby::DSL::Context,
        path_template: "/items",
        schema_name: nil,
        path_parameters: []
      )

      metadata = {
        openapi_path_context: path_ctx,
        openapi_operation: operation
      }

      allow(helper).to receive(:resolve_let).and_return(nil)
      allow(helper).to receive(:resolve_let).with(:request_params).and_return({})
      allow(helper).to receive(:resolve_let).with(:request_headers).and_return({})
      allow(helper).to receive(:resolve_let).with(:request_body).and_return(nil)
      allow(helper).to receive(:resolve_let).with(:Accept).and_return("application/json")
      allow(helper).to receive(:resolve_let).with(:page).and_return(2)

      helper.submit_openapi_request(metadata)

      expect(helper.last_request).to eq(
        path: "/items?page=2",
        headers: {"Accept" => "application/json"}
      )
    end

    it "sends query params under their camelized name" do
      operation = OpenapiRuby::DSL::OperationContext.new(:get, "Test")
      operation.parameter(name: :page_size, in: :query, schema: {type: :integer})

      helper_class = Class.new do
        include OpenapiRuby::Adapters::RSpec::ExampleHelpers

        def get(path, **args)
          @last_request = {path: path, **args}
        end

        attr_reader :last_request
      end
      helper = helper_class.new

      path_ctx = instance_double(
        OpenapiRuby::DSL::Context,
        path_template: "/items",
        schema_name: nil,
        path_parameters: []
      )

      metadata = {
        openapi_path_context: path_ctx,
        openapi_operation: operation
      }

      allow(helper).to receive(:resolve_let).and_return(nil)
      allow(helper).to receive(:resolve_let).with(:request_params).and_return({})
      allow(helper).to receive(:resolve_let).with(:request_headers).and_return({})
      allow(helper).to receive(:resolve_let).with(:request_body).and_return(nil)
      allow(helper).to receive(:resolve_let).with(:Accept).and_return("application/json")
      # The let keeps the declared snake_case name
      allow(helper).to receive(:resolve_let).with(:page_size).and_return(20)

      helper.submit_openapi_request(metadata)

      expect(helper.last_request[:path]).to eq("/items?pageSize=20")
    end
  end

  describe "#assert_api_response" do
    let(:helper_class) do
      Class.new do
        include OpenapiRuby::Adapters::RSpec::ExampleHelpers
      end
    end

    let(:transport) { instance_double(OpenapiRuby::Testing::Transport::RailsIntegration, dispatch: nil) }
    let(:helper) do
      helper_class.new.tap do |instance|
        allow(instance).to receive(:openapi_transport).and_return(transport)
        allow(instance).to receive(:openapi_response).and_return(
          double(status: 200, body: "[]") # rubocop:disable RSpec/VerifiedDoubles
        )
      end
    end

    def declare_context
      context = OpenapiRuby::DSL::Context.new("/items/{item_id}")
      context.parameter(name: :item_id, in: :path, schema: {type: :integer})
      context.get("List") do
        parameter name: :page_size, in: :query, schema: {type: :integer}
        response(200, "OK")
      end
      context
    end

    it "sends declared params under their camelized name" do
      context = declare_context
      allow(helper).to receive(:find_api_context_for).and_return(context)

      helper.assert_api_response(:get, 200, params: {page_size: 20}, path_params: {item_id: 7})

      expect(transport).to have_received(:dispatch).with(
        :get, "/items/7?pageSize=20", headers: {"Accept" => "application/json"}
      )
    end

    it "keeps the declared names when camelize_keys is off" do
      OpenapiRuby.configuration.camelize_keys = false
      context = declare_context
      allow(helper).to receive(:find_api_context_for).and_return(context)

      helper.assert_api_response(:get, 200, params: {page_size: 20}, path_params: {item_id: 7})

      expect(transport).to have_received(:dispatch).with(
        :get, "/items/7?page_size=20", headers: {"Accept" => "application/json"}
      )
    end
  end
end
