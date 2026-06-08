# frozen_string_literal: true

module OpenapiRuby
  module Generator
    # Helpers backing the `openapi_ruby:generate` rake task. Extracted
    # so the framework detection / script generation logic is testable
    # without booting Rake.
    module RakeTaskSupport
      module_function

      def detect_test_framework
        rspec = File.exist?("spec/spec_helper.rb") || File.exist?("spec/rails_helper.rb")
        minitest = File.exist?("test/test_helper.rb")

        if rspec && minitest
          "hybrid"
        elsif rspec
          "rspec"
        elsif minitest
          "minitest"
        else
          raise ArgumentError,
            "Could not detect test framework. Set FRAMEWORK=rspec, FRAMEWORK=minitest, or FRAMEWORK=hybrid."
        end
      end

      def default_pattern_for(framework)
        case framework
        when "rspec" then "spec/**/*_spec.rb"
        when "minitest" then "test/**/*_test.rb"
        when "hybrid" then "spec/**/*_spec.rb,test/**/*_test.rb"
        end
      end

      def generate_script(framework, pattern)
        case framework
        when "rspec" then rspec_script(pattern)
        when "minitest" then minitest_script(pattern)
        when "hybrid" then hybrid_script(pattern)
        else
          raise ArgumentError, "Unknown test framework '#{framework}'."
        end
      end

      def rspec_script(pattern)
        <<~RUBY
          require "rspec/core"
          $LOAD_PATH.unshift(File.expand_path("spec")) unless $LOAD_PATH.include?(File.expand_path("spec"))
          #{glob_loads(pattern)}
          OpenapiRuby::Generator::SchemaWriter.generate_all!
        RUBY
      end

      def minitest_script(pattern)
        <<~RUBY
          require "openapi_ruby/minitest"
          #{glob_loads(pattern)}
          OpenapiRuby::Generator::SchemaWriter.generate_all!
        RUBY
      end

      # Loads both adapters and both file globs in one process. Useful
      # during a phased RSpec → Minitest migration where the suite
      # holds both DSL styles. Consumers should guard
      # `require "rails/test_help"` and `require "rspec/rails"` in
      # their test helpers with `unless ENV["OPENAPI_RUBY_GENERATING"]`
      # so the two test frameworks don't both register Rails lazy
      # hooks in the same process — only the DSL needs to be live for
      # schema generation.
      def hybrid_script(pattern)
        <<~RUBY
          require "rspec/core"
          require "openapi_ruby/rspec"
          require "openapi_ruby/minitest"
          $LOAD_PATH.unshift(File.expand_path("spec")) unless $LOAD_PATH.include?(File.expand_path("spec"))
          $LOAD_PATH.unshift(File.expand_path("test")) unless $LOAD_PATH.include?(File.expand_path("test"))
          #{glob_loads(pattern)}
          OpenapiRuby::Generator::SchemaWriter.generate_all!
        RUBY
      end

      def glob_loads(pattern)
        pattern.split(",").map do |p|
          %[Dir.glob(#{p.strip.inspect}).sort.each { |f| require File.expand_path(f) }]
        end.join("\n")
      end
    end
  end
end
