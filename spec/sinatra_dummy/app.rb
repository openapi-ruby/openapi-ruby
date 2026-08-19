# frozen_string_literal: true

require "sinatra/base"
require "json"
require_relative "config/openapi_ruby"
require_relative "post_store"

# A Sinatra app is a Rack app: the validation middleware installs onto its
# class-level stack, and nothing else about the gem needs to know what
# framework this is.
class App < Sinatra::Base
  OpenapiRuby::Middleware::Installer.install!(self, root: __dir__)

  get "/api/v1/posts" do
    json 200, PostStore.all(author: params["author"])
  end

  get "/api/v1/posts/:id" do
    post = PostStore.find(params["id"])
    halt(*json_args(404, {error: "Not found"})) unless post

    json 200, post
  end

  post "/api/v1/posts" do
    attributes = parsed_request_body

    if attributes["title"].to_s.strip.empty?
      halt(*json_args(422, {errors: ["title can't be blank"]}))
    end

    json 201, PostStore.create(
      title: attributes["title"],
      body: attributes["body"],
      author: attributes["author"]
    )
  end

  delete "/api/v1/posts/:id" do
    halt(*json_args(404, {error: "Not found"})) unless PostStore.find(params["id"])

    PostStore.delete(params["id"])
    status 204
    body ""
  end

  private

  def json(code, payload)
    status code
    content_type :json
    payload.to_json
  end

  def json_args(code, payload)
    [code, {"content-type" => "application/json"}, payload.to_json]
  end

  def parsed_request_body
    raw = request.body.read
    request.body.rewind
    raw.empty? ? {} : JSON.parse(raw)
  rescue JSON::ParserError
    {}
  end
end
