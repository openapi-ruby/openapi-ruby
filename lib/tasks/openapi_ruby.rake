# frozen_string_literal: true

namespace :openapi_ruby do
  desc "Generate OpenAPI schema files from spec definitions and components"
  task generate: :environment do
    framework = ENV.fetch("FRAMEWORK", detect_test_framework).to_s

    case framework
    when "rspec"
      generate_with_rspec
    when "minitest"
      generate_with_minitest
    else
      abort "Unknown test framework '#{framework}'. Set FRAMEWORK=rspec or FRAMEWORK=minitest."
    end
  end
end

def detect_test_framework
  if File.exist?("spec/spec_helper.rb") || File.exist?("spec/rails_helper.rb")
    "rspec"
  elsif File.exist?("test/test_helper.rb")
    "minitest"
  else
    abort "Could not detect test framework. Set FRAMEWORK=rspec or FRAMEWORK=minitest."
  end
end

def generate_with_rspec
  pattern = ENV.fetch("PATTERN", "spec/**/*_spec.rb")
  command = "bundle exec rspec --pattern '#{pattern}' --dry-run --order defined"
  puts "Generating OpenAPI schemas (RSpec)..."
  system(command) || abort("Schema generation failed")
end

def generate_with_minitest
  pattern = ENV.fetch("PATTERN", "test/**/*_test.rb")
  puts "Generating OpenAPI schemas (Minitest)..."

  # Load Rails environment and minitest adapter
  require "openapi_ruby/minitest"

  # Load all test files to trigger api_path registrations.
  # Minitest's api_path registers DSL contexts at class load time,
  # so simply requiring the files is enough.
  Dir.glob(pattern).each { |f| require File.expand_path(f) }

  # Generate schemas from the registered contexts
  OpenapiRuby::Generator::SchemaWriter.generate_all!
end
