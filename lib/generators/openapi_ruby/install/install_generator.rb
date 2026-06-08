# frozen_string_literal: true

module OpenapiRuby
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install openapi_ruby: creates initializer, test helper, and component directory"

      def create_initializer
        template "initializer.rb.tt", "config/initializers/openapi_ruby.rb"
      end

      def create_test_helper
        if rspec?
          template "openapi_helper.rb.tt", "spec/openapi_helper.rb"
        else
          template "openapi_helper.rb.tt", "test/openapi_helper.rb"
        end
      end

      def create_component_directories
        empty_directory "app/api_components/schemas"
        empty_directory "app/api_components/parameters"
        empty_directory "app/api_components/security_schemes"
      end

      def create_schema_output_directory
        empty_directory "openapi"
      end

      def mount_engine
        route 'mount OpenapiRuby::Engine => "/api-docs"'
      end

      private

      def rspec?
        File.exist?(File.join(destination_root, "spec"))
      end

      def app_name
        Rails.application.class.module_parent_name
      rescue
        "MyApp"
      end
    end
  end
end
