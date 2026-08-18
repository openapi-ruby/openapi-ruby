# auto_register: false
# frozen_string_literal: true

module HanamiDummy
  # In-memory store — this app exists to exercise openapi-ruby, not a database.
  class PostStore
    class << self
      def all
        records.values
      end

      def find(id)
        records[id.to_i]
      end

      def create(title:, body: nil, author: nil)
        id = (records.keys.max || 0) + 1
        records[id] = {id: id, title: title, body: body, author: author}
      end

      def delete(id)
        records.delete(id.to_i)
      end

      def reset!
        @records = {}
      end

      private

      def records
        @records ||= {}
      end
    end
  end
end
