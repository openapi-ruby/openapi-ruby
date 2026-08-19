# frozen_string_literal: true

require "rake"
require "shellwords"
require "openapi_ruby/generator/rake_task_support"

module OpenapiRuby
  # The Rails engine picks up lib/tasks/*.rake on its own; other hosts add
  #
  #   require "openapi_ruby/rake_tasks"
  #
  # to their Rakefile. Both routes end up here, so the task is defined once.
  module RakeTasks
    extend Rake::DSL

    def self.install!
      return if Rake::Task.task_defined?("openapi_ruby:generate")

      namespace :openapi_ruby do
        desc "Generate OpenAPI schema files from spec definitions and components"
        task :generate do
          support = OpenapiRuby::Generator::RakeTaskSupport
          framework = ENV.fetch("FRAMEWORK") { support.detect_test_framework }.to_s
          pattern = ENV.fetch("PATTERN") { support.default_pattern_for(framework) }

          # Spawn a subprocess so the host's env defaults to "test" cleanly,
          # just like rswag did with RSpec::Core::RakeTask.
          script = support.generate_script(framework, pattern)
          command = "bundle exec ruby -e #{Shellwords.escape(script)}"

          puts "Generating OpenAPI schemas (#{framework})..."
          system(support.subprocess_env, command) || abort("Schema generation failed")
        end
      end
    end
  end
end

OpenapiRuby::RakeTasks.install!
