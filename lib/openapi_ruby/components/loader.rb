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
        @@loaded = true # rubocop:disable Style/ClassVars
        self
      end

      def to_openapi_hash
        ensure_loaded!
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

          Dir.glob(File.join(expanded, "**/")).sort.each do |dir_path|
            relative = dir_path.sub("#{expanded}/", "").chomp("/")
            next if relative.empty?

            const_name = relative.camelize
            const_name.split("::").inject(Object) do |parent, name|
              if parent.const_defined?(name, false)
                parent.const_get(name, false)
              else
                parent.const_set(name, Module.new)
              end
            end
          end
        end
      end

      def load_component_files!
        scope_paths = OpenapiRuby.configuration.component_scope_paths

        # Collect all files with their base paths, then sort globally by relative
        # path to ensure consistent load order across multiple base paths.
        # This prevents cross-directory inheritance issues (e.g., a subclass in
        # packs/ai_feedback loading before its superclass in packs/api).
        all_files = collect_all_files

        if scope_paths.any?
          load_with_scope_inference(all_files, scope_paths)
        else
          all_files.each { |entry| require entry[:file] }
        end
      end

      def collect_all_files
        files = []
        @paths.each do |base_path|
          expanded = File.expand_path(base_path)
          next unless Dir.exist?(expanded)

          Dir[File.join(expanded, "**", "*.rb")].each do |file|
            relative = file.sub("#{expanded}/", "")
            files << {file: file, base_path: expanded, relative: relative}
          end
        end
        files.sort_by { |entry| entry[:relative] }
      end

      def load_with_scope_inference(all_files, scope_paths)
        # Build a map of file path → inferred scope before loading.
        file_scope_map = {}
        all_files.each do |entry|
          scope = infer_scope(entry[:relative], scope_paths)
          file_scope_map[entry[:file]] = scope if scope
        end

        # Load files, tracking which classes each file registers.
        # We track both newly loaded AND already-loaded classes via before/after diffs.
        class_to_file = {}
        all_files.each do |entry|
          registered_before = Registry.instance.all_registered_classes.dup
          require entry[:file]
          new_classes = Registry.instance.all_registered_classes - registered_before
          new_classes.each { |klass| class_to_file[klass] = entry[:file] }
        end

        # For components that were already autoloaded by Rails (require returned false,
        # so they didn't appear in the before/after diff), try to match them to files
        # by their class name → file path convention.
        Registry.instance.all_registered_classes.each do |klass|
          next if class_to_file.key?(klass)

          source_file = find_source_file_for(klass)
          class_to_file[klass] = source_file if source_file
        end

        # Correct cross-scope inheritance misattribution: when Admin::V1::Schemas::ItemPrice
        # inherits from V1::Schemas::ItemPrice, loading the admin file auto-loads the parent
        # via Ruby autoloading. The diff-based tracking then maps the parent to the admin file.
        # Fix by preferring the conventional file path when it exists and differs.
        class_to_file.each do |klass, file|
          conventional_file = find_source_file_for(klass)
          if conventional_file && conventional_file != file && file_scope_map.key?(conventional_file)
            class_to_file[klass] = conventional_file
          end
        end

        # Assign scopes to all registered components based on their source file.
        class_to_file.each do |klass, file|
          next if klass._component_scopes_explicitly_set

          inferred_scope = file_scope_map[file]
          next unless inferred_scope

          if inferred_scope == :shared
            klass._component_scopes = []
            klass._component_scopes_explicitly_set = true
          elsif inferred_scope.is_a?(Array)
            Registry.instance.unregister(klass)
            klass._component_scopes = inferred_scope
            klass._component_scopes_explicitly_set = true
            Registry.instance.register(klass)
          else
            Registry.instance.unregister(klass)
            klass._component_scopes = [inferred_scope]
            Registry.instance.register(klass)
          end
        end
      end

      def find_source_file_for(klass)
        return nil unless klass.name

        # Try the conventional path based on the class name (e.g., Internal::V1::Schemas::User → internal/v1/schemas/user.rb)
        relative = klass.name.underscore + ".rb"
        @paths.each do |base_path|
          expanded = File.expand_path(base_path)
          candidate = File.join(expanded, relative)
          return candidate if File.exist?(candidate)
        end
        nil
      end

      def infer_scope(relative_path, scope_paths)
        scope_paths.sort_by { |prefix, _| -prefix.length }.each do |prefix, scope|
          if relative_path.start_with?("#{prefix}/")
            return scope.is_a?(Array) ? scope.map(&:to_sym) : scope&.to_sym
          end
        end
        nil
      end

      def filter_type(type)
        ensure_loaded!
        to_openapi_hash[type.to_s] || {}
      end

      @@loaded = false # rubocop:disable Style/ClassVars

      def ensure_loaded!
        return if @@loaded

        load!
      end
    end
  end
end
