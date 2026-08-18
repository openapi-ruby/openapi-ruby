# frozen_string_literal: true

class Schemas::Post
  include OpenapiRuby::Components::Base

  schema(
    type: :object,
    required: %w[id title],
    properties: {
      id: {type: :integer},
      title: {type: :string},
      body: {type: [:string, :null]},
      author: {type: [:string, :null]}
    }
  )

  skip_key_transformation true
end
