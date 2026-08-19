# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

# Each alternate host's dummy app runs in its own bundle, so Rails and the
# other framework never have to boot in one process.
#
# Unbundled: Bundler exports BUNDLE_LOCKFILE next to BUNDLE_GEMFILE, and an
# inherited one makes the child write its resolution into this bundle's
# Gemfile.lock.
def run_dummy_app_specs(gemfile, dir, command)
  gemfile_path = File.expand_path("gemfiles/#{gemfile}", __dir__)

  Bundler.with_unbundled_env do
    Dir.chdir(dir) do
      sh({"BUNDLE_GEMFILE" => gemfile_path}, command)
    end
  end
end

namespace :spec do
  desc "Run the Hanami dummy app's specs in the Rails-free bundle"
  task :hanami do
    run_dummy_app_specs("hanami.gemfile", "spec/hanami_dummy", "bundle exec rspec")
  end

  desc "Run the Sinatra dummy app's specs and tests in the Rails-free bundle"
  task :sinatra do
    run_dummy_app_specs("sinatra.gemfile", "spec/sinatra_dummy", "bundle exec rspec")
    run_dummy_app_specs("sinatra.gemfile", "spec/sinatra_dummy", "bundle exec ruby -Itest test/posts_test.rb")
  end

  desc "Run every host's dummy app suite"
  task hosts: %i[hanami sinatra]
end

task default: :spec
