# frozen_string_literal: true

module HanamiDummy
  module Actions
    module Posts
      class Index < HanamiDummy::Action
        def handle(request, response)
          posts = PostStore.all
          author = request.params[:author]
          posts = posts.select { |post| post[:author] == author } if author

          json(response, 200, posts)
        end
      end
    end
  end
end
