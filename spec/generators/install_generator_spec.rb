# frozen_string_literal: true

require "spec_helper"
require_relative "../support/rails_app"
require "rails/generators"
require "generators/openapi_ruby/install/install_generator"
require "tmpdir"
require "securerandom"

RSpec.describe OpenapiRuby::Generators::InstallGenerator do
  let(:destination) { File.join(Dir.tmpdir, "openapi_ruby_gen_#{SecureRandom.hex(4)}") }

  before do
    FileUtils.mkdir_p(destination)
    FileUtils.mkdir_p(File.join(destination, "spec"))
    FileUtils.mkdir_p(File.join(destination, "config"))
    File.write(File.join(destination, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
  end

  after { FileUtils.rm_rf(destination) }

  def run_generator
    described_class.start([], destination_root: destination, shell: Thor::Shell::Basic.new)
  end

  it "creates the initializer" do
    run_generator
    path = File.join(destination, "config/initializers/openapi_ruby.rb")
    expect(File.exist?(path)).to be true
    content = File.read(path)
    expect(content).to include("OpenapiRuby.configure")
    expect(content).to include("config.schemas")
  end

  it "creates the openapi helper for rspec" do
    run_generator
    path = File.join(destination, "spec/openapi_helper.rb")
    expect(File.exist?(path)).to be true
    expect(File.read(path)).to include("openapi_ruby/rspec")
  end

  it "creates component directories" do
    run_generator
    expect(Dir.exist?(File.join(destination, "app/api_components/schemas"))).to be true
    expect(Dir.exist?(File.join(destination, "app/api_components/parameters"))).to be true
    expect(Dir.exist?(File.join(destination, "app/api_components/security_schemes"))).to be true
  end

  it "creates openapi output directory" do
    run_generator
    expect(Dir.exist?(File.join(destination, "openapi"))).to be true
  end

  it "adds engine route" do
    run_generator
    content = File.read(File.join(destination, "config/routes.rb"))
    expect(content).to include("OpenapiRuby::Engine")
  end
end
