# frozen_string_literal: true

# RSpec copies parent metadata into child groups by reference, so `api_path`
# has to build a new array. Mutating in place leaks a nested declaration back to
# the parent and sideways to its siblings, which is what made nesting useless as
# a way to tell sibling paths apart.

require "spec_helper"
require "openapi_ruby/adapters/rspec"

RSpec.describe OpenapiRuby::Adapters::RSpec::ExampleGroupHelpers do
  def group(metadata)
    Class.new do
      extend OpenapiRuby::Adapters::RSpec::ExampleGroupHelpers

      define_singleton_method(:metadata) { metadata }
    end
  end

  def templates(metadata)
    metadata[:openapi_api_contexts].map(&:path_template)
  end

  describe "#api_path" do
    it "scopes a nested declaration to the group that made it" do
      parent = {openapi_schema_name: :test}
      group(parent).api_path("/timers") { get("List") { response(200, "ok") } }

      start = parent.dup
      stop = parent.dup
      group(start).api_path("/timers/{id}/start") { put("Start") { response(200, "ok") } }
      group(stop).api_path("/timers/{id}/stop") { put("Stop") { response(200, "ok") } }

      expect(templates(parent)).to eq(["/timers"])
      expect(templates(start)).to eq(["/timers", "/timers/{id}/start"])
      expect(templates(stop)).to eq(["/timers", "/timers/{id}/stop"])
    end

    it "returns the context so it can be passed back as api_path:" do
      context = group({openapi_schema_name: :test}).api_path("/timers") { get("List") { response(200, "ok") } }

      expect(context.path_template).to eq("/timers")
    end
  end
end
