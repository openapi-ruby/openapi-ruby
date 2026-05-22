# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "Users API", type: :openapi do
  before do
    Post.delete_all
    User.delete_all
  end

  path "/api/v1/users" do
    get "List users" do
      tags "Users"
      operationId "listUsers"
      produces "application/json"

      response 200, "returns all users" do
        schema type: :array, items: Schemas::User

        before { User.create!(name: "Jane", email: "jane@example.com") }

        run_test! do
          body = JSON.parse(response.body)
          expect(body.length).to eq(1)
          expect(body.first["name"]).to eq("Jane")
          expect(body.first).to have_key("id")
          expect(body.first).to have_key("createdAt")
        end
      end
    end

    post "Create a user" do
      tags "Users"
      operationId "createUser"
      consumes "application/json"
      produces "application/json"

      parameter name: :name, in: :query, schema: {type: :string}, required: true
      parameter name: :email, in: :query, schema: {type: :string}, required: true

      response 201, "user created" do
        schema Schemas::User

        let(:name) { "Jane" }
        let(:email) { "jane@example.com" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["name"]).to eq("Jane")
          expect(body["email"]).to eq("jane@example.com")
          expect(body["id"]).to be_a(Integer)
        end
      end

      response 422, "validation errors" do
        schema Schemas::ValidationErrors

        let(:name) { "" }
        let(:email) { "" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["errors"]).to be_an(Array)
          expect(body["errors"]).not_to be_empty
        end
      end
    end
  end

  path "/api/v1/users/{id}" do
    parameter name: :id, in: :path, schema: {type: :integer}, required: true

    get "Get a user" do
      tags "Users"
      operationId "getUser"
      produces "application/json"

      response 200, "user found" do
        schema Schemas::User

        let(:id) { User.create!(name: "Jane", email: "jane@example.com").id }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["name"]).to eq("Jane")
          expect(body["email"]).to eq("jane@example.com")
        end
      end

      response 404, "user not found" do
        schema Schemas::ErrorResponse

        let(:id) { 0 }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["error"]).to eq("Not found")
        end
      end
    end

    patch "Update a user" do
      tags "Users"
      operationId "updateUser"
      consumes "application/json"
      produces "application/json"

      parameter name: :name, in: :query, schema: {type: :string}
      parameter name: :email, in: :query, schema: {type: :string}

      response 200, "user updated" do
        schema Schemas::User

        let(:id) { User.create!(name: "Jane", email: "jane@example.com").id }
        let(:name) { "Jane Updated" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["name"]).to eq("Jane Updated")
        end
      end

      response 404, "user not found" do
        schema Schemas::ErrorResponse

        let(:id) { 0 }

        run_test!
      end
    end

    delete "Delete a user" do
      tags "Users"
      operationId "deleteUser"

      response 204, "user deleted" do
        let(:id) { User.create!(name: "Jane", email: "jane@example.com").id }

        run_test! do
          expect(User.find_by(id: id)).to be_nil
        end
      end

      response 404, "user not found" do
        schema Schemas::ErrorResponse

        let(:id) { 0 }

        run_test!
      end
    end
  end
end
