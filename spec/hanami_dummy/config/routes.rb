# frozen_string_literal: true

module HanamiDummy
  class Routes < Hanami::Routes
    get "/api/v1/posts", to: "posts.index"
    post "/api/v1/posts", to: "posts.create"
    get "/api/v1/posts/:id", to: "posts.show"
    delete "/api/v1/posts/:id", to: "posts.destroy"

    mount OpenapiRuby::RackApp, at: "/api-docs"
  end
end
