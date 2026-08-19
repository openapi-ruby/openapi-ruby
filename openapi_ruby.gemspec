# frozen_string_literal: true

require_relative "lib/openapi_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "openapi-ruby"
  spec.version = OpenapiRuby::VERSION
  spec.authors = ["Morten Hartvig"]
  spec.email = ["morten@hartvigsen.dev"]

  spec.summary = "OpenAPI 3.0/3.1 toolkit for Rails and Hanami — spec generation, schema components, and runtime validation"
  spec.description = "A unified OpenAPI toolkit for Rails and Hanami that combines test-driven spec " \
                     "generation, reusable schema components as Ruby classes, and runtime request/response " \
                     "validation middleware. Supports OpenAPI 3.0 and 3.1. Works with both RSpec and Minitest."
  spec.homepage = "https://github.com/openapi-ruby/openapi-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "json_schemer", "~> 2.4"
  spec.add_dependency "rack", ">= 2.0"
end
