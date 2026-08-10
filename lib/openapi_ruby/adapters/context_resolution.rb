# frozen_string_literal: true

module OpenapiRuby
  module Adapters
    # Shared by the Minitest and RSpec Style 2 adapters.
    #
    # Style 2 separates the `api_path` declaration from the request that
    # exercises it, so the request has to be matched back to a declaration.
    # Everything used to do that here is a hard fact about the request, never a
    # guess: the verb, which path params the template needs against which the
    # caller supplied, whether the candidate declares the status the assertion
    # demands, and whether the remaining params are declared on the operation.
    #
    # That leaves one case it cannot decide. `/timers/{id}` and
    # `/timers/{id}/start` under the same verb, the same status and the same
    # `{id}` are indistinguishable from the call site — the information simply
    # isn't there. Picking one silently sends the request to the wrong endpoint
    # and validates it against the wrong response schema, so a test passes while
    # exercising something else. Raise instead, and name the candidates; the
    # author resolves it by passing `api_path:` or by scoping the declarations.
    module ContextResolution
      module_function

      def resolve(contexts, method, path_params, owner:, params: {}, expected_status: nil, api_path: nil)
        if api_path
          selected = find_declared(contexts, api_path)
          raise OpenapiRuby::Error, unknown_path_message(contexts, api_path, owner) unless selected
          return selected
        end

        candidates = contexts.select { |ctx| ctx.operations.key?(method.to_s) }
        return candidates.first if candidates.size <= 1

        supplied = keys_of(params) | keys_of(path_params)
        required = keys_of(path_params)

        candidates = narrow(candidates) { |ctx| path_params_fit?(ctx, required, supplied) }
        if expected_status
          candidates = narrow(candidates) { |ctx| declares_status?(ctx, method, expected_status) }
        end
        candidates = fewest_unaccounted(candidates, method, supplied)

        return candidates.first if candidates.size == 1

        raise OpenapiRuby::AmbiguousApiPath, ambiguity_message(candidates, method, owner)
      end

      # A template only fits if it needs no path param the caller did not supply,
      # and uses every param the caller explicitly declared as one.
      def path_params_fit?(context, required, supplied)
        template = template_params(context)

        (required - template).empty? && (template - supplied).empty?
      end

      def declares_status?(context, method, expected_status)
        context.operations[method.to_s].responses.key?(expected_status.to_s)
      end

      # Prefer the candidate that can explain the most supplied keys as either a
      # path param of its own template or a parameter declared on it. A key that
      # fits nowhere means the request was probably meant for a sibling path.
      def fewest_unaccounted(candidates, method, supplied)
        ranked = candidates.group_by { |ctx| (supplied - accounted_keys(ctx, method)).size }

        ranked[ranked.keys.min]
      end

      def accounted_keys(context, method)
        declared = context.path_parameters + (context.operations[method.to_s]&.parameters || [])

        template_params(context) | declared.filter_map { |param| param["name"]&.to_s }
      end

      def template_params(context)
        context.path_template.scan(/\{(\w+)\}/).flatten
      end

      def find_declared(contexts, api_path)
        template = api_path.respond_to?(:path_template) ? api_path.path_template : api_path.to_s

        contexts.find { |ctx| ctx.path_template == template }
      end

      def narrow(candidates)
        narrowed = candidates.select { |ctx| yield(ctx) }

        narrowed.empty? ? candidates : narrowed
      end

      def keys_of(params)
        params.keys.map(&:to_s)
      end

      def ambiguity_message(matches, method, owner)
        paths = matches.map { |ctx| ctx.path_template.inspect }.join(", ")

        "#{method.to_s.upcase} matches more than one api_path in #{owner}: #{paths}. " \
          "Requests are matched on the verb, the path params supplied and the declared " \
          "response status, none of which tell these apart. Pass api_path: to pick one, " \
          "or declare each api_path in its own class or nested describe block."
      end

      def unknown_path_message(contexts, api_path, owner)
        template = api_path.respond_to?(:path_template) ? api_path.path_template : api_path.to_s
        declared = contexts.map { |ctx| ctx.path_template.inspect }.join(", ")

        "No api_path #{template.inspect} declared in #{owner}. " \
          "Declared: #{declared.empty? ? "none" : declared}."
      end
    end
  end
end
