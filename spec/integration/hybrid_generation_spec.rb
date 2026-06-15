# frozen_string_literal: true

# Verifies the `hybrid` framework mode: detection, default pattern, and
# script generation. The hybrid script is the workflow used during a
# phased RSpec → Minitest migration where the suite holds both styles.

require "spec_helper"

RSpec.describe OpenapiRuby::Generator::RakeTaskSupport do
  describe ".default_pattern_for" do
    it "covers spec/ and test/ when framework is hybrid" do
      expect(described_class.default_pattern_for("hybrid"))
        .to eq("spec/**/*_spec.rb,test/**/*_test.rb")
    end

    it "returns nil for unknown frameworks" do
      expect(described_class.default_pattern_for("unknown")).to be_nil
    end
  end

  describe ".detect_test_framework" do
    around do |example|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) { example.run }
      end
    end

    it "returns hybrid when both spec/ and test/ helpers exist" do
      FileUtils.mkdir_p("spec")
      FileUtils.mkdir_p("test")
      File.write("spec/spec_helper.rb", "")
      File.write("test/test_helper.rb", "")

      expect(described_class.detect_test_framework).to eq("hybrid")
    end

    it "returns rspec when only spec/ exists" do
      FileUtils.mkdir_p("spec")
      File.write("spec/spec_helper.rb", "")
      expect(described_class.detect_test_framework).to eq("rspec")
    end

    it "returns minitest when only test/ exists" do
      FileUtils.mkdir_p("test")
      File.write("test/test_helper.rb", "")
      expect(described_class.detect_test_framework).to eq("minitest")
    end

    it "raises when neither helper exists" do
      expect { described_class.detect_test_framework }.to raise_error(ArgumentError, /Could not detect/)
    end
  end

  describe ".generate_script for rspec" do
    let(:script) do
      described_class.generate_script("rspec", "spec/**/*_spec.rb")
    end

    it "puts spec/ on $LOAD_PATH so `require \"spec_helper\"` / `require \"rails_helper\"` resolve" do
      expect(script).to include('$LOAD_PATH.unshift(File.expand_path("spec"))')
    end
  end

  describe ".generate_script for minitest" do
    let(:script) do
      described_class.generate_script("minitest", "test/**/*_test.rb")
    end

    it "puts test/ on $LOAD_PATH so `require \"test_helper\"` / `require \"openapi_helper\"` resolve" do
      expect(script).to include('$LOAD_PATH.unshift(File.expand_path("test"))')
    end
  end

  describe ".generate_script for hybrid" do
    let(:script) do
      described_class.generate_script("hybrid", "spec/**/*_spec.rb,test/**/*_test.rb")
    end

    it "requires both adapters" do
      expect(script).to include('require "openapi_ruby/rspec"')
      expect(script).to include('require "openapi_ruby/minitest"')
    end

    it "scopes spec globs to the spec/ load path" do
      expect(script).to include('load_with_path.call("spec", "spec/**/*_spec.rb")')
    end

    it "scopes test globs to the test/ load path" do
      expect(script).to include('load_with_path.call("test", "test/**/*_test.rb")')
    end

    it "calls SchemaWriter.generate_all!" do
      expect(script).to include("OpenapiRuby::Generator::SchemaWriter.generate_all!")
    end

    it "ensures each glob resolves its own helper file" do
      # When spec/ and test/ both define a require-able file with the
      # same name (e.g. openapi_helper.rb), the spec glob must resolve
      # to the spec/ version and the test glob to the test/ version.
      expect(script.scan("load_with_path.call").size).to eq(2)
    end
  end

  describe ".generate_script for unknown framework" do
    it "raises ArgumentError" do
      expect { described_class.generate_script("nope", "x") }
        .to raise_error(ArgumentError, /Unknown test framework/)
    end
  end

  describe "DSL registration across both styles" do
    before do
      OpenapiRuby::DSL::MetadataStore.clear!
      require "openapi_ruby/rspec"
      require "openapi_ruby/minitest"
    end

    after { OpenapiRuby::DSL::MetadataStore.clear! }

    it "merges contexts from RSpec path() and Minitest api_path() into the same MetadataStore" do
      # Simulate a Style 1 RSpec spec registering /v1/things
      rspec_group = RSpec.describe("RSpec API", type: :openapi, openapi_schema_name: :hybrid_test) do
        path "/v1/things" do
          get("List things") { response(200, "ok") }
        end
      end
      rspec_group.run

      # Simulate a Style 2 Minitest test registering /v1/widgets
      minitest_class = Class.new(Minitest::Test) do
        include OpenapiRuby::Adapters::Minitest::DSL

        openapi_schema :hybrid_test
        api_path "/v1/widgets" do
          get("List widgets") { response(200, "ok") }
        end
      end
      # Force the class to be retained
      _ = minitest_class

      paths = OpenapiRuby::DSL::MetadataStore.contexts_for(:hybrid_test).map(&:path_template)
      expect(paths).to include("/v1/things", "/v1/widgets")
    end
  end
end
