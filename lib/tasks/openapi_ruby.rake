# frozen_string_literal: true

namespace :openapi_ruby do
  desc "Generate OpenAPI schema files from spec definitions and components"
  task :generate do
    framework = ENV.fetch("FRAMEWORK", detect_test_framework).to_s
    pattern = ENV.fetch("PATTERN", default_pattern_for(framework))

    # Spawn a subprocess so RAILS_ENV defaults to "test" cleanly,
    # just like rswag did with RSpec::Core::RakeTask.
    env = {"RAILS_ENV" => ENV.fetch("RAILS_ENV", "test")}
    script = generate_script(framework, pattern)
    command = "bundle exec ruby -e #{Shellwords.escape(script)}"

    puts "Generating OpenAPI schemas (#{framework})..."
    system(env, command) || abort("Schema generation failed")
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

def default_pattern_for(framework)
  case framework
  when "rspec" then "spec/**/*_spec.rb"
  when "minitest" then "test/**/*_test.rb"
  end
end

def generate_script(framework, pattern)
  case framework
  when "rspec"
    <<~RUBY
      require "rspec/core"
      $LOAD_PATH.unshift(File.expand_path("spec")) unless $LOAD_PATH.include?(File.expand_path("spec"))
      #{pattern.split(",").map { |p| %[Dir.glob(#{p.strip.inspect}).sort.each { |f| require File.expand_path(f) }] }.join("\n")}
      OpenapiRuby::Generator::SchemaWriter.generate_all!
    RUBY
  when "minitest"
    <<~RUBY
      require "openapi_ruby/minitest"
      #{pattern.split(",").map { |p| %[Dir.glob(#{p.strip.inspect}).sort.each { |f| require File.expand_path(f) }] }.join("\n")}
      OpenapiRuby::Generator::SchemaWriter.generate_all!
    RUBY
  else
    abort "Unknown test framework '#{framework}'."
  end
end
