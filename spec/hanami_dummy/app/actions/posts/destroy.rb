# frozen_string_literal: true

module HanamiDummy
  module Actions
    module Posts
      class Destroy < HanamiDummy::Action
        def handle(request, response)
          return not_found(response) unless PostStore.find(request.params[:id])

          PostStore.delete(request.params[:id])
          response.status = 204
          response.body = ""
        end
      end
    end
  end
end
