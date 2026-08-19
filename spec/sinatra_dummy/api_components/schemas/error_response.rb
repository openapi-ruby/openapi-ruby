# frozen_string_literal: true

class Schemas::ErrorResponse
  include OpenapiRuby::Components::Base

  schema(
    type: :object,
    required: %w[error],
    properties: {
      error: {type: :string}
    }
  )

  skip_key_transformation true
end
