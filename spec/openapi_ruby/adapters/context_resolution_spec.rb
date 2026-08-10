# frozen_string_literal: true

# Style 2 matches a request back to a declared api_path using only hard facts
# about the request: the verb, the path params supplied, the status the
# assertion demands and which params the candidate declares. Sibling paths that
# agree on all of those cannot be told apart, so that case raises rather than
# quietly picking one.

require "spec_helper"

RSpec.describe OpenapiRuby::Adapters::ContextResolution do
  def context_for(template, *verbs, &block)
    ctx = OpenapiRuby::DSL::Context.new(template, schema_name: :test)
    verbs.each { |verb| ctx.public_send(verb, "op") { response(200, "ok") } }
    ctx.instance_eval(&block) if block
    ctx
  end

  describe ".resolve" do
    it "returns the only match" do
      contexts = [context_for("/timers", :get)]

      resolved = described_class.resolve(contexts, :get, {}, owner: "TimersTest")

      expect(resolved.path_template).to eq("/timers")
    end

    it "returns nil when nothing matches the verb" do
      contexts = [context_for("/timers", :get)]

      expect(described_class.resolve(contexts, :delete, {}, owner: "TimersTest")).to be_nil
    end

    it "separates a collection path from a member path by path params" do
      contexts = [context_for("/timers", :get), context_for("/timers/{id}", :get)]

      expect(described_class.resolve(contexts, :get, {}, owner: "T").path_template).to eq("/timers")
      expect(described_class.resolve(contexts, :get, {id: 1}, owner: "T").path_template).to eq("/timers/{id}")
    end

    it "skips a candidate needing a path param that was never supplied" do
      contexts = [context_for("/projects/{project_id}/timers", :get), context_for("/timers/{id}", :get)]

      expect(described_class.resolve(contexts, :get, {id: 1}, owner: "T").path_template)
        .to eq("/timers/{id}")
    end

    it "reads a path param supplied as a request param" do
      contexts = [context_for("/timers", :get), context_for("/timers/{id}", :get)]

      resolved = described_class.resolve(contexts, :get, {}, params: {id: 1}, owner: "T")

      expect(resolved.path_template).to eq("/timers/{id}")
    end

    # `/timers?id=1` and `/timers/1` are both honest readings of the same call,
    # so this one has to be spelled out by the caller.
    it "raises when the shared key is a query param on one path and a path param on the other" do
      collection = context_for("/timers") do
        get("List") do
          parameter(name: "id", in: "query", schema: {type: "integer"})
          response(200, "ok")
        end
      end
      contexts = [collection, context_for("/timers/{id}", :get)]

      expect { described_class.resolve(contexts, :get, {}, params: {id: 1}, owner: "T") }
        .to raise_error(OpenapiRuby::AmbiguousApiPath, /Pass api_path:/)

      expect(described_class.resolve(contexts, :get, {id: 1}, owner: "T").path_template)
        .to eq("/timers/{id}")
    end

    it "separates siblings by the status the assertion demands" do
      update = context_for("/timers/{id}", :put)
      start = context_for("/timers/{id}/start", :put)
      start.operations["put"].response(422, "unprocessable")

      resolved = described_class.resolve(
        [update, start], :put, {id: 1}, expected_status: 422, owner: "T"
      )

      expect(resolved.path_template).to eq("/timers/{id}/start")
    end

    it "ignores the status filter when no candidate declares it" do
      contexts = [context_for("/timers", :get)]

      resolved = described_class.resolve(contexts, :get, {}, expected_status: 404, owner: "T")

      expect(resolved.path_template).to eq("/timers")
    end

    # The case that used to resolve to whichever was declared first.
    it "raises when sibling paths agree on verb, path params and status" do
      contexts = [
        context_for("/timers/{id}", :put),
        context_for("/timers/{id}/start", :put),
        context_for("/timers/{id}/stop", :put)
      ]

      expect { described_class.resolve(contexts, :put, {id: 1}, expected_status: 200, owner: "TimersTest") }
        .to raise_error(OpenapiRuby::AmbiguousApiPath, /TimersTest/)
    end

    it "names the candidates so the author can see the collision" do
      contexts = [context_for("/users", :get), context_for("/users/current", :get)]

      expect { described_class.resolve(contexts, :get, {}, owner: "UsersTest") }
        .to raise_error(OpenapiRuby::AmbiguousApiPath, %r{"/users".*"/users/current"})
    end

    it "does not raise when the colliding paths declare different verbs" do
      contexts = [context_for("/timers/{id}", :put), context_for("/timers/{id}/start", :delete)]

      expect(described_class.resolve(contexts, :put, {id: 1}, owner: "T").path_template)
        .to eq("/timers/{id}")
    end

    context "with an explicit api_path" do
      let(:contexts) do
        [context_for("/timers/{id}", :put), context_for("/timers/{id}/start", :put)]
      end

      it "picks the named declaration out of an otherwise ambiguous set" do
        resolved = described_class.resolve(
          contexts, :put, {id: 1}, expected_status: 200, api_path: "/timers/{id}/start", owner: "T"
        )

        expect(resolved.path_template).to eq("/timers/{id}/start")
      end

      it "accepts the context object api_path returns" do
        resolved = described_class.resolve(contexts, :put, {id: 1}, api_path: contexts.last, owner: "T")

        expect(resolved.path_template).to eq("/timers/{id}/start")
      end

      it "raises when the named path was never declared" do
        expect { described_class.resolve(contexts, :put, {id: 1}, api_path: "/timers/{id}/pause", owner: "T") }
          .to raise_error(OpenapiRuby::Error, %r{"/timers/\{id\}/pause".*"/timers/\{id\}"}m)
      end
    end
  end
end
