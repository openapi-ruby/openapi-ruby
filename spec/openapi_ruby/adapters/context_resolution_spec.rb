# frozen_string_literal: true

# Style 2 matches a request back to a declared api_path on the verb and
# whether path params were given. That is enough for one resource per class
# and not enough beyond it, so the ambiguous case has to raise rather than
# quietly pick one.

require "spec_helper"

RSpec.describe OpenapiRuby::Adapters::ContextResolution do
  def context_for(template, *verbs)
    ctx = OpenapiRuby::DSL::Context.new(template, schema_name: :test)
    verbs.each { |verb| ctx.public_send(verb, "op") { response(200, "ok") } }
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

    # The case that used to resolve to whichever was declared first.
    it "raises when sibling paths share a verb and both take path params" do
      contexts = [
        context_for("/timers/{id}", :put),
        context_for("/timers/{id}/start", :put),
        context_for("/timers/{id}/stop", :put)
      ]

      expect { described_class.resolve(contexts, :put, {id: 1}, owner: "TimersTest") }
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
  end
end
