# frozen_string_literal: true

module OpenapiRuby
  module Adapters
    # Shared by the Minitest and RSpec Style 2 adapters.
    #
    # Style 2 separates the `api_path` declaration from the request that
    # exercises it, so the request has to be matched back to a declaration.
    # The only thing distinguishing them is the verb and whether path params
    # were supplied — which is enough for the intended shape of one resource
    # per class (a collection path plus a member path), and not enough for
    # anything beyond it.
    #
    # `/timers/{id}`, `/timers/{id}/start` and `/timers/{id}/stop` all match
    # "PUT with a path param". Picking the first silently sends the request to
    # the wrong endpoint and validates it against the wrong response schema,
    # so a test can pass while exercising something else entirely. Raise
    # instead, and name the candidates.
    module ContextResolution
      module_function

      def matching_contexts(contexts, method, path_params)
        has_path_params = path_params.any?

        contexts.select do |ctx|
          next false unless ctx.operations.key?(method.to_s)

          if has_path_params
            ctx.path_template.include?("{")
          else
            !ctx.path_template.include?("{")
          end
        end
      end

      def resolve(contexts, method, path_params, owner:)
        matches = matching_contexts(contexts, method, path_params)
        return matches.first if matches.size <= 1

        raise OpenapiRuby::AmbiguousApiPath, ambiguity_message(matches, method, owner)
      end

      def ambiguity_message(matches, method, owner)
        paths = matches.map { |ctx| ctx.path_template.inspect }.join(", ")

        "#{method.to_s.upcase} matches more than one api_path in #{owner}: #{paths}. " \
          "Requests are matched on the verb and whether path params were given, which " \
          "cannot tell these apart. Declare each api_path in its own class."
      end
    end
  end
end
