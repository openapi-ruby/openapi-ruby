# frozen_string_literal: true

module HanamiDummy
  module Actions
    module Posts
      class Create < HanamiDummy::Action
        def handle(request, response)
          attributes = request.params.to_h

          if attributes[:title].to_s.strip.empty?
            return json(response, 422, {errors: ["title can't be blank"]})
          end

          post = PostStore.create(
            title: attributes[:title],
            body: attributes[:body],
            author: attributes[:author]
          )

          json(response, 201, post)
        end
      end
    end
  end
end
