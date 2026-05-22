# frozen_string_literal: true

require "test_helper"

class PostsApiTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :public_api

  setup do
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

  test "GET /api/v1/posts returns all posts" do
    Post.create!(title: "First post", body: "Hello", user: @user)
    Post.create!(title: "Second post", user: @user)

    assert_api_response :get, 200 do
      assert_equal 2, parsed_body.length
      assert_equal "First post", parsed_body.first["title"]
    end
  end

  test "GET /api/v1/posts filters by user_id" do
    other_user = User.create!(name: "John", email: "john@example.com")
    Post.create!(title: "Jane's post", user: @user)
    Post.create!(title: "John's post", user: other_user)

    assert_api_response :get, 200, params: {user_id: @user.id} do
      assert_equal 1, parsed_body.length
      assert_equal "Jane's post", parsed_body.first["title"]
    end
  end

  test "POST /api/v1/posts creates a post" do
    assert_api_response :post, 201, body: {title: "New post", body: "Content", user_id: @user.id} do
      assert_equal "New post", parsed_body["title"]
      assert_equal @user.id, parsed_body["user_id"]
      assert parsed_body["id"].is_a?(Integer)
    end
  end

  test "POST /api/v1/posts with invalid data returns 422" do
    assert_api_response :post, 422, body: {title: "", user_id: @user.id} do
      assert parsed_body["errors"].is_a?(Array)
      assert_not_empty parsed_body["errors"]
    end
  end

  test "GET /api/v1/posts/:id returns a post" do
    post = Post.create!(title: "My post", body: "Content", user: @user)

    assert_api_response :get, 200, path_params: {id: post.id} do
      assert_equal "My post", parsed_body["title"]
      assert_equal post.id, parsed_body["id"]
    end
  end

  test "GET /api/v1/posts/:id returns 404 for missing post" do
    assert_api_response :get, 404, path_params: {id: 0} do
      assert_equal "Not found", parsed_body["error"]
    end
  end

  test "DELETE /api/v1/posts/:id deletes a post" do
    post = Post.create!(title: "Delete me", user: @user)

    assert_api_response :delete, 204, path_params: {id: post.id}

    assert_nil Post.find_by(id: post.id)
  end

  test "DELETE /api/v1/posts/:id returns 404 for missing post" do
    assert_api_response :delete, 404, path_params: {id: 0}
  end
end
