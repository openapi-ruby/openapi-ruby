# frozen_string_literal: true

# In-memory store — this app exists to exercise openapi-ruby, not a database.
class PostStore
  class << self
    def all(author: nil)
      records = @records ||= {}
      posts = records.values
      author ? posts.select { |post| post[:author] == author } : posts
    end

    def find(id)
      (@records ||= {})[id.to_i]
    end

    def create(title:, body: nil, author: nil)
      records = @records ||= {}
      id = (records.keys.max || 0) + 1
      records[id] = {id: id, title: title, body: body, author: author}
    end

    def delete(id)
      (@records ||= {}).delete(id.to_i)
    end

    def reset!
      @records = {}
    end
  end
end
