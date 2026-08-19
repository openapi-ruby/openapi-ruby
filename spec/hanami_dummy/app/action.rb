# auto_register: false
# frozen_string_literal: true

require "hanami/action"

module HanamiDummy
  class Action < Hanami::Action
    private

    def json(response, status, payload)
      response.status = status
      response.headers["Content-Type"] = "application/json"
      response.body = payload.to_json
    end

    def not_found(response)
      json(response, 404, {error: "Not found"})
    end
  end
end
