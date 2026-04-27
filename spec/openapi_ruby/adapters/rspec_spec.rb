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
        schema_name: nil
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
  end
end
