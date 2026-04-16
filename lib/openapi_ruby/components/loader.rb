# frozen_string_literal: true

module OpenapiRuby
  module Components
    class Loader
      attr_reader :paths

      def initialize(paths: nil, scope: nil)
        @paths = paths || OpenapiRuby.configuration.component_paths
        @scope = scope&.to_sym
      end

      def load!
        define_namespace_modules!
        load_component_files!
        self
      end

      def to_openapi_hash
        Registry.instance.to_openapi_hash(scope: @scope)
      end

      def schemas
        filter_type(:schemas)
      end

      def parameters
        filter_type(:parameters)
      end

      def security_schemes
        filter_type(:securitySchemes)
      end

      def request_bodies
        filter_type(:requestBodies)
      end

      def responses
        filter_type(:responses)
      end

      def headers
        filter_type(:headers)
      end

      def examples
        filter_type(:examples)
      end

      def links
        filter_type(:links)
      end

      def callbacks
        filter_type(:callbacks)
      end

      private

      def define_namespace_modules!
        @paths.each do |path|
          expanded = File.expand_path(path)
          next unless Dir.exist?(expanded)

          define_nested_modules(expanded, expanded)
        end
      end

      def define_nested_modules(base_path, current_path)
        Dir.children(current_path).select { |f| File.directory?(File.join(current_path, f)) }.each do |dir|
          mod_name = dir.camelize.to_sym
          Object.const_set(mod_name, Module.new) unless Object.const_defined?(mod_name)

          child_path = File.join(current_path, dir)
          define_nested_modules(base_path, child_path)
        end
      end

      def load_component_files!
        scope_paths = OpenapiRuby.configuration.component_scope_paths

        if scope_paths.any?
          load_with_scope_inference(scope_paths)
        else
          component_files.each { |f| require f }
        end
      end

      def load_with_scope_inference(scope_paths)
        @paths.each do |base_path|
          expanded = File.expand_path(base_path)
          next unless Dir.exist?(expanded)

          files = Dir[File.join(expanded, "**", "*.rb")].sort

          files.each do |file|
            relative = file.sub("#{expanded}/", "")
            inferred_scope = infer_scope(relative, scope_paths)

            registered_before = Registry.instance.all_registered_classes.dup
            require file
            registered_after = Registry.instance.all_registered_classes

            new_classes = registered_after - registered_before
            new_classes.each do |klass|
              next if klass._component_scopes_explicitly_set

              if inferred_scope == :shared
                # Shared components have empty scopes (included in all specs)
                klass._component_scopes = []
              elsif inferred_scope
                Registry.instance.unregister(klass)
                klass._component_scopes = [inferred_scope]
                Registry.instance.register(klass)
              end
            end
          end
        end
      end

      def infer_scope(relative_path, scope_paths)
        # Match longest prefix first for specificity
        scope_paths.sort_by { |prefix, _| -prefix.length }.each do |prefix, scope|
          return scope&.to_sym if relative_path.start_with?("#{prefix}/")
        end
        nil
      end

      def component_files
        @paths.flat_map do |path|
          expanded = File.expand_path(path)
          Dir[File.join(expanded, "**", "*.rb")]
        end
      end

      def filter_type(type)
        to_openapi_hash[type.to_s] || {}
      end
    end
  end
end
