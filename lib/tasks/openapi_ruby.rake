# frozen_string_literal: true

require "openapi_ruby/generator/rake_task_support"

namespace :openapi_ruby do
  desc "Generate OpenAPI schema files from spec definitions and components"
  task :generate do
    support = OpenapiRuby::Generator::RakeTaskSupport
    framework = ENV.fetch("FRAMEWORK") { support.detect_test_framework }.to_s
    pattern = ENV.fetch("PATTERN") { support.default_pattern_for(framework) }

    # Spawn a subprocess so RAILS_ENV defaults to "test" cleanly,
    # just like rswag did with RSpec::Core::RakeTask.
    env = {"RAILS_ENV" => ENV.fetch("RAILS_ENV", "test"), "OPENAPI_RUBY_GENERATING" => "true"}
    script = support.generate_script(framework, pattern)
    command = "bundle exec ruby -e #{Shellwords.escape(script)}"

    puts "Generating OpenAPI schemas (#{framework})..."
    system(env, command) || abort("Schema generation failed")
  end
end
