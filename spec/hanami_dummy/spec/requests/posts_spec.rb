# frozen_string_literal: true

require "spec_helper"

# Written exactly as a Hanami user would: the schema at the top, plain RSpec
# examples underneath. Requests go out through rack-test.
RSpec.describe "Posts API", type: :openapi do
  openapi_schema :public_api

  api_path "/posts" do
    get "List posts" do
      tags "Posts"
      operationId "listPosts"
      produces "application/json"
      parameter name: :author, in: :query, schema: {type: :string}, required: false

      response 200, "returns posts" do
        schema type: :array, items: {"$ref" => "#/components/schemas/Post"}
      end
    end

    post "Create a post" do
      tags "Posts"
      operationId "createPost"
      consumes "application/json"
      produces "application/json"

      request_body(
        required: true,
        content: {
          "application/json" => {
            schema: {"$ref" => "#/components/schemas/PostInput"}
          }
        }
      )

      response 201, "post created" do
        schema "$ref" => "#/components/schemas/Post"
      end

      response 422, "validation errors" do
        schema "$ref" => "#/components/schemas/ValidationErrors"
      end
    end
  end

  api_path "/posts/{id}" do
    get "Get a post" do
      tags "Posts"
      operationId "getPost"
      produces "application/json"

      response 200, "post found" do
        schema "$ref" => "#/components/schemas/Post"
      end

      response 404, "post not found" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
      end
    end

    delete "Delete a post" do
      tags "Posts"
      operationId "deletePost"

      response 204, "post deleted"

      response 404, "post not found" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
      end
    end
  end

  it "GET /api/v1/posts returns all posts" do
    HanamiDummy::PostStore.create(title: "First post", body: "Hello")
    HanamiDummy::PostStore.create(title: "Second post")

    assert_api_response :get, 200 do
      expect(parsed_body.length).to eq(2)
      expect(parsed_body.first["title"]).to eq("First post")
    end
  end

  it "GET /api/v1/posts filters by author" do
    HanamiDummy::PostStore.create(title: "Jane's post", author: "Jane")
    HanamiDummy::PostStore.create(title: "John's post", author: "John")

    assert_api_response :get, 200, params: {author: "Jane"} do
      expect(parsed_body.length).to eq(1)
      expect(parsed_body.first["title"]).to eq("Jane's post")
    end
  end

  it "POST /api/v1/posts creates a post" do
    assert_api_response :post, 201, body: {title: "New post", body: "Content", author: "Jane"} do
      expect(parsed_body["title"]).to eq("New post")
      expect(parsed_body["author"]).to eq("Jane")
      expect(parsed_body["id"]).to be_a(Integer)
    end
  end

  it "POST /api/v1/posts with a blank title returns 422" do
    assert_api_response :post, 422, body: {title: "  "} do
      expect(parsed_body["errors"]).to eq(["title can't be blank"])
    end
  end

  it "GET /api/v1/posts/:id returns a post" do
    post = HanamiDummy::PostStore.create(title: "My post", body: "Content")

    assert_api_response :get, 200, path_params: {id: post[:id]} do
      expect(parsed_body["title"]).to eq("My post")
      expect(parsed_body["id"]).to eq(post[:id])
    end
  end

  it "GET /api/v1/posts/:id returns 404 for a missing post" do
    assert_api_response :get, 404, path_params: {id: 0} do
      expect(parsed_body["error"]).to eq("Not found")
    end
  end

  it "DELETE /api/v1/posts/:id deletes a post" do
    post = HanamiDummy::PostStore.create(title: "Delete me")

    assert_api_response :delete, 204, path_params: {id: post[:id]}

    expect(HanamiDummy::PostStore.find(post[:id])).to be_nil
  end

  it "DELETE /api/v1/posts/:id returns 404 for a missing post" do
    assert_api_response :delete, 404, path_params: {id: 0}
  end
end
