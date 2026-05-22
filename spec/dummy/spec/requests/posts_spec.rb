# frozen_string_literal: true

require "openapi_helper"

# Demonstrates the minitest-style DSL in RSpec: schema definition at the top,
# normal RSpec examples underneath using assert_api_response.
RSpec.describe "Posts API (api_path style)", type: :openapi do
  openapi_schema :public_api

  before do
    Post.delete_all
    User.delete_all
    @user = User.create!(name: "Jane", email: "jane@example.com")
  end

  api_path "/api/v1/posts" do
    get "List posts" do
      tags "Posts"
      operationId "listPosts"
      produces "application/json"
      parameter name: :user_id, in: :query, schema: {type: :integer}, required: false

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

  api_path "/api/v1/posts/{id}" do
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

  # --- Normal RSpec examples using assert_api_response ---

  it "GET /api/v1/posts returns all posts" do
    Post.create!(title: "First post", body: "Hello", user: @user)
    Post.create!(title: "Second post", user: @user)

    assert_api_response :get, 200 do
      expect(parsed_body.length).to eq(2)
      expect(parsed_body.first["title"]).to eq("First post")
    end
  end

  it "GET /api/v1/posts filters by user_id" do
    other_user = User.create!(name: "John", email: "john@example.com")
    Post.create!(title: "Jane's post", user: @user)
    Post.create!(title: "John's post", user: other_user)

    assert_api_response :get, 200, params: {user_id: @user.id} do
      expect(parsed_body.length).to eq(1)
      expect(parsed_body.first["title"]).to eq("Jane's post")
    end
  end

  it "POST /api/v1/posts creates a post" do
    assert_api_response :post, 201, body: {title: "New post", body: "Content", user_id: @user.id} do
      expect(parsed_body["title"]).to eq("New post")
      expect(parsed_body["user_id"]).to eq(@user.id)
      expect(parsed_body["id"]).to be_a(Integer)
    end
  end

  it "POST /api/v1/posts with invalid data returns 422" do
    assert_api_response :post, 422, body: {title: "", user_id: @user.id} do
      expect(parsed_body["errors"]).to be_an(Array)
      expect(parsed_body["errors"]).not_to be_empty
    end
  end

  it "GET /api/v1/posts/:id returns a post" do
    post = Post.create!(title: "My post", body: "Content", user: @user)

    assert_api_response :get, 200, path_params: {id: post.id} do
      expect(parsed_body["title"]).to eq("My post")
      expect(parsed_body["id"]).to eq(post.id)
    end
  end

  it "GET /api/v1/posts/:id returns 404 for missing post" do
    assert_api_response :get, 404, path_params: {id: 0} do
      expect(parsed_body["error"]).to eq("Not found")
    end
  end

  it "DELETE /api/v1/posts/:id deletes a post" do
    post = Post.create!(title: "Delete me", user: @user)

    assert_api_response :delete, 204, path_params: {id: post.id}

    expect(Post.find_by(id: post.id)).to be_nil
  end

  it "DELETE /api/v1/posts/:id returns 404 for missing post" do
    assert_api_response :delete, 404, path_params: {id: 0}
  end
end
