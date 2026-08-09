# frozen_string_literal: true

# Runs the real generation script against the dummy app in a subprocess and
# asserts it only *loads* the test files.
#
# The dummy app's test_helper requires "minitest/autorun", the same way a Rails
# app's test_helper pulls it in transitively via rails/test_help. Without the
# AutorunSuppressor, requiring the test files registers Minitest's at_exit hook
# and the suite runs as a side effect of generating the schema — slow, and
# failing whenever any unrelated test fails.

require "spec_helper"

RSpec.describe "schema generation without running tests" do
  let(:dummy_root) { File.expand_path("../dummy", __dir__) }
  let(:output_dir) { File.join(dummy_root, "tmp/openapi") }
  let(:gemfile) { File.expand_path("../../Gemfile", __dir__) }

  before { FileUtils.mkdir_p(output_dir) }
  after { FileUtils.rm_rf(output_dir) }

  let(:generation_output) do
    script = OpenapiRuby::Generator::RakeTaskSupport.generate_script(
      "minitest", "test/**/*_test.rb"
    )

    env = {
      "RAILS_ENV" => "test",
      "OPENAPI_RUBY_GENERATING" => "true",
      "BUNDLE_GEMFILE" => gemfile
    }

    Dir.chdir(dummy_root) do
      IO.popen(env, ["bundle", "exec", "ruby", "-e", script], err: [:child, :out], &:read)
    end
  end

  it "loads the dummy app's tests without executing them" do
    expect(generation_output).not_to match(/\d+ runs, \d+ assertions/),
      "Minitest executed the suite during generation:\n#{generation_output}"
    expect(generation_output).not_to include("# Running:")
  end

  it "still collects the api_path declarations from the files it loaded" do
    generation_output

    written = Dir.glob(File.join(output_dir, "**", "*.yaml"))
    expect(written).not_to be_empty, "generation wrote no schema"

    document = YAML.safe_load_file(written.first)
    expect(document["paths"]).to include("/api/v1/posts")
  end
end
