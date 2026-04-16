# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe OpenapiRuby::Components::Loader do
  before do
    OpenapiRuby::Components::Registry.instance.clear!
  end

  describe "scope inference from directory structure" do
    let(:tmpdir) { Dir.mktmpdir("api_components") }

    after { FileUtils.rm_rf(tmpdir) }

    def write_component(path, class_name, module_nesting: nil, scope: nil)
      full_path = File.join(tmpdir, path)
      FileUtils.mkdir_p(File.dirname(full_path))

      scope_line = scope ? "        component_scopes :#{scope}" : ""
      module_open = module_nesting ? "module #{module_nesting}\n" : ""
      module_close = module_nesting ? "end\n" : ""

      File.write(full_path, <<~RUBY)
        #{module_open}class #{class_name}
          include OpenapiRuby::Components::Base
#{scope_line}
          schema(type: :object)
        end
        #{module_close}
      RUBY
    end

    it "infers scopes from directory prefixes" do
      write_component("v1/schemas/user.rb", "InferredV1User")
      write_component("admin/v1/schemas/user.rb", "InferredAdminUser")
      write_component("shared/v1/schemas/error.rb", "InferredSharedError")

      OpenapiRuby.configuration.component_scope_paths = {
        "v1" => :v1,
        "admin/v1" => :admin,
        "shared/v1" => :shared
      }

      loader = described_class.new(paths: [tmpdir])
      loader.load!

      v1_user = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "InferredV1User" }
      admin_user = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "InferredAdminUser" }
      shared_error = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "InferredSharedError" }

      expect(v1_user._component_scopes).to eq([:v1])
      expect(admin_user._component_scopes).to eq([:admin])
      # :shared scope means empty scopes (included in all specs)
      expect(shared_error._component_scopes).to eq([])
    end

    it "does not override explicitly set scopes" do
      write_component("v1/schemas/explicit.rb", "ExplicitScopeComp", scope: :custom)

      OpenapiRuby.configuration.component_scope_paths = {
        "v1" => :v1
      }

      loader = described_class.new(paths: [tmpdir])
      loader.load!

      comp = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "ExplicitScopeComp" }
      expect(comp._component_scopes).to eq([:custom])
    end

    it "does not infer scopes when component_scope_paths is empty" do
      write_component("v1/schemas/noinfer.rb", "NoInferComp")

      OpenapiRuby.configuration.component_scope_paths = {}

      loader = described_class.new(paths: [tmpdir])
      loader.load!

      comp = OpenapiRuby::Components::Registry.instance.all_registered_classes.find { |c| c.name == "NoInferComp" }
      expect(comp._component_scopes).to eq([])
    end
  end
end
