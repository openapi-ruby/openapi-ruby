# frozen_string_literal: true

class Schemas::PostInput
  include OpenapiRuby::Components::Base

  # No minLength on title: a blank title is schema-valid so it reaches the
  # action, which rejects it with a 422 — that path is what the specs cover.
  schema(
    type: :object,
    required: %w[title],
    properties: {
      title: {type: :string},
      body: {type: [:string, :null]},
      author: {type: [:string, :null]}
    }
  )

  skip_key_transformation true
end
