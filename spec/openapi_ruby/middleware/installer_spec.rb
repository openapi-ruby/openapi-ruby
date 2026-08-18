# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe OpenapiRuby::Middleware::Installer do
  # Stands in for Rails' `app.middleware` and Hanami's `config.middleware`,
  # which is all the API this needs.
  let(:stack) do
    Class.new do
      attr_reader :uses

      def initialize = @uses = []

      def use(middleware, **options) = @uses << [middleware, options]
    end.new
  end

  let(:root) { Pathname.new(Dir.mktmpdir) }

  before do
    FileUtils.mkdir_p(root.join("openapi"))
    File.write(root.join("openapi", "public_api.yaml"), {"openapi" => "3.1.0", "paths" => {}}.to_yaml)

    OpenapiRuby.configure do |config|
      config.schemas = {public_api: {info: {title: "Public API", version: "1.0"}, prefix: "/api/v1"}}
    end
  end

  after { FileUtils.remove_entry(root) }

  it "installs nothing while both validations are disabled" do
    described_class.install!(stack, root: root)

    expect(stack.uses).to be_empty
  end

  it "installs request validation with the schema's prefix" do
    OpenapiRuby.configuration.request_validation = :enabled

    described_class.install!(stack, root: root)

    expect(stack.uses.map(&:first)).to eq([OpenapiRuby::Middleware::RequestValidation])
    expect(stack.uses.first.last).to include(mode: :enabled, prefix: "/api/v1")
  end

  it "installs both validations when both are configured" do
    OpenapiRuby.configuration.request_validation = :warn_only
    OpenapiRuby.configuration.response_validation = :enabled

    described_class.install!(stack, root: root)

    expect(stack.uses.map(&:first)).to eq([
      OpenapiRuby::Middleware::RequestValidation,
      OpenapiRuby::Middleware::ResponseValidation
    ])
  end

  it "shares one schema resolver between the two validations" do
    OpenapiRuby.configuration.request_validation = :enabled
    OpenapiRuby.configuration.response_validation = :enabled

    described_class.install!(stack, root: root)

    resolvers = stack.uses.map { |(_, options)| options[:schema_resolver] }
    expect(resolvers.uniq.size).to eq(1)
  end

  it "skips schemas that have not been generated yet" do
    OpenapiRuby.configuration.request_validation = :enabled
    FileUtils.rm(root.join("openapi", "public_api.yaml"))

    described_class.install!(stack, root: root)

    expect(stack.uses).to be_empty
  end

  # The generation subprocess loads the host app; installing validation
  # middleware against a schema it is about to rewrite is pointless at best.
  it "installs nothing during schema generation" do
    OpenapiRuby.configuration.request_validation = :enabled

    begin
      ENV["OPENAPI_RUBY_GENERATING"] = "true"
      described_class.install!(stack, root: root)
    ensure
      ENV.delete("OPENAPI_RUBY_GENERATING")
    end

    expect(stack.uses).to be_empty
  end

  it "resolves the schema path under the given root" do
    OpenapiRuby.configuration.schema_output_format = :json

    path = described_class.resolve_schema_path(OpenapiRuby.configuration, :public_api, root)

    expect(path).to eq(root.join("openapi", "public_api.json").to_s)
  end
end
