# frozen_string_literal: true

require_relative "test_helper"

class PostsTest < ApiTest
  openapi_schema :public_api

  api_path "/posts" do
    get "List posts" do
      tags "Posts"
      produces "application/json"

      response 200, "returns posts" do
        schema type: :array, items: {"$ref" => "#/components/schemas/Post"}
      end
    end

    post "Create a post" do
      tags "Posts"
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
    end
  end

  def test_lists_posts
    PostStore.create(title: "First post")

    assert_api_response :get, 200 do
      assert_equal "First post", parsed_body.first["title"]
    end
  end

  def test_creates_a_post
    assert_api_response :post, 201, body: {title: "New post"} do
      assert_equal "New post", parsed_body["title"]
      assert_kind_of Integer, parsed_body["id"]
    end
  end
end
