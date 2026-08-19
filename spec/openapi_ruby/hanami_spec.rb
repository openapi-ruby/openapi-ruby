# frozen_string_literal: true

require "spec_helper"
require "openapi_ruby/hanami"

RSpec.describe OpenapiRuby::Hanami do
  describe ".install_middleware!" do
    let(:stack) do
      Class.new do
        attr_reader :uses

        def initialize = @uses = []

        def use(middleware, **options) = @uses << [middleware, options]
      end.new
    end

    let(:hanami_config) do
      Struct.new(:middleware, :root).new(stack, "/srv/hanami_app")
    end

    before { OpenapiRuby.configuration.request_validation = :enabled }

    it "installs onto the config's middleware stack, rooted at the config's root" do
      expect(OpenapiRuby::Middleware::Installer).to receive(:install!)
        .with(stack, root: "/srv/hanami_app")

      described_class.install_middleware!(hanami_config)
    end

    it "accepts a bare middleware stack" do
      expect(OpenapiRuby::Middleware::Installer).to receive(:install!)
        .with(stack, root: OpenapiRuby.app_root)

      described_class.install_middleware!(stack)
    end

    it "falls back to the detected app root when the config carries none" do
      config = Struct.new(:middleware, :root).new(stack, nil)

      expect(OpenapiRuby::Middleware::Installer).to receive(:install!)
        .with(stack, root: OpenapiRuby.app_root)

      described_class.install_middleware!(config)
    end

    it "installs the middleware for real" do
      described_class.install_middleware!(hanami_config)

      expect(stack.uses).to be_empty # no generated schema at that root
    end
  end

  describe ".install_rspec!" do
    it "wires rack-test into :openapi example groups" do
      rspec_config = Class.new do
        attr_reader :includes

        def initialize = @includes = []

        def include(mod, **metadata) = @includes << [mod, metadata]
      end.new

      described_class.install_rspec!(rspec_config)

      expect(rspec_config.includes).to eq([
        [Rack::Test::Methods, {type: :openapi}],
        [described_class::RackTestApp, {type: :openapi}]
      ])
    end
  end

  describe described_class::RackTestApp do
    it "drives the Hanami app" do
      hanami_app = Object.new
      stub_const("Hanami", Module.new.tap { |m| m.define_singleton_method(:app) { hanami_app } })

      context = Object.new.extend(described_class)

      expect(context.app).to be(hanami_app)
    end
  end

  # Requiring openapi_ruby/hanami before ::Hanami itself must still move the
  # component default out of Hanami's autoloaded app/ directory.
  it "sets the Hanami component path default at require time" do
    lib_path = File.expand_path("../../lib", __dir__)
    script = <<~RUBY
      $LOAD_PATH.unshift(#{lib_path.inspect})
      require "openapi_ruby"
      require "openapi_ruby/hanami"
      puts OpenapiRuby.configuration.component_paths.inspect
    RUBY

    output = IO.popen([RbConfig.ruby, "-e", script], err: [:child, :out], &:read)

    expect(output).to include('["config/api_components"]'), "subprocess failed:\n#{output}"
  end

  it "leaves an explicitly configured component path alone" do
    OpenapiRuby.configuration.component_paths = ["lib/my_app/api_components"]

    described_class.apply_component_path_default!

    expect(OpenapiRuby.configuration.component_paths).to eq(["lib/my_app/api_components"])
  end
end
