# frozen_string_literal: true

module HanamiDummy
  module Actions
    module Posts
      class Show < HanamiDummy::Action
        def handle(request, response)
          post = PostStore.find(request.params[:id])
          return not_found(response) unless post

          json(response, 200, post)
        end
      end
    end
  end
end
