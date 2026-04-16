# frozen_string_literal: true

OpenapiRuby::Engine.routes.draw do
  get "schemas", to: "schemas#index", as: :schemas
  get "schemas/*id", to: "schemas#show", as: :schema

  get "ui", to: "ui#index", as: :ui
  get "oauth2-redirect.html", to: "ui#oauth2_redirect", as: :oauth2_redirect
end
