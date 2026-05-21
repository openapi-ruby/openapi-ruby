# frozen_string_literal: true

require "openapi_helper"

# Verifies that the RSpec adapter validates response bodies against the
# declared `schema(...)` (not just the status code). Uses
# `openapi_schema_name: :public_api` so the adapter can resolve $ref
# schemas against the full document.
RSpec.describe "Response body validation", type: :openapi, openapi_schema_name: :public_api do
  path "/api/v1/users" do
    get "List users" do
      tags "Users"
      operationId "validation_listUsers"
      produces "application/json"

      response 200, "returns valid users" do
        schema type: :array, items: {"$ref" => "#/components/schemas/User"}

        before { User.delete_all && User.create!(name: "Jane", email: "jane@example.com") }

        # Happy path: real response satisfies the schema
        run_test!
      end
    end
  end

  it "fails when the response body does not match the documented schema" do
    User.delete_all
    User.create!(name: "Jane", email: "jane@example.com")

    # Build a response_ctx pointing at a schema the response doesn't satisfy.
    # We use the existing `User` component but require a field the real
    # response omits (`bogusField`) — JSONSchemer will flag the missing key.
    response_ctx = OpenapiRuby::DSL::ResponseContext.new(200, "drift")
    response_ctx.schema(
      type: :object,
      required: ["bogusField"],
      properties: {bogusField: {type: :string}}
    )

    validator = OpenapiRuby::Testing::ResponseValidator.new(
      OpenapiRuby::Adapters::RSpec.validation_document_for(:public_api)
    )

    errors = validator.validate(
      response_body: {"id" => 1, "name" => "Jane", "email" => "jane@example.com"},
      status_code: 200,
      response_context: response_ctx
    )

    expect(errors).not_to be_empty
  end
end
