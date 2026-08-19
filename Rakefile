# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc "Run the Hanami dummy app's specs in the Rails-free bundle"
  task :hanami do
    gemfile = File.expand_path("gemfiles/hanami.gemfile", __dir__)

    # Unbundled: Bundler exports BUNDLE_LOCKFILE next to BUNDLE_GEMFILE, and an
    # inherited one makes the child write its resolution into this bundle's
    # Gemfile.lock.
    Bundler.with_unbundled_env do
      Dir.chdir("spec/hanami_dummy") do
        sh({"BUNDLE_GEMFILE" => gemfile}, "bundle exec rspec")
      end
    end
  end
end

task default: :spec
