# frozen_string_literal: true

module OpenapiRuby
  class << self
    # Which framework the gem is running inside. Rails wins a tie: an app with
    # both constants loaded is a Rails app that happens to have another
    # framework's gems in the bundle. :rack covers Sinatra, Roda, and bare Rack
    # — anything whose only shared surface is the Rack SPEC.
    def host
      if defined?(::Rails)
        :rails
      elsif defined?(::Hanami)
        :hanami
      else
        :rack
      end
    end

    def rails_host?
      host == :rails
    end

    def hanami_host?
      host == :hanami
    end

    def rack_host?
      host == :rack
    end

    # Application root, used to resolve the configured (relative)
    # schema_output_dir. Falls back to the working directory: a bare Rack app
    # has no root of its own, and the generation subprocess loads test files
    # without booting an app at all.
    def app_root
      root = if defined?(::Rails) && ::Rails.respond_to?(:root) && ::Rails.root
        ::Rails.root
      elsif hanami_booted?
        ::Hanami.app.root
      else
        Dir.pwd
      end

      root.to_s
    end

    private

    def hanami_booted?
      defined?(::Hanami) && ::Hanami.respond_to?(:app?) && ::Hanami.app?
    end
  end
end
