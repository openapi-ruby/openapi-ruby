# frozen_string_literal: true

module OpenapiRuby
  class SchemasController < ActionController::API
    def show
      document = Serving.schema_document(params[:id], request: request)
      return head :not_found unless document

      content, content_type = document
      render plain: content, content_type: content_type
    end

    def index
      render json: {schemas: Serving.schema_names}
    end
  end
end
