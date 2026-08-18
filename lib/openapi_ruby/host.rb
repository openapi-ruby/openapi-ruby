# frozen_string_literal: true

module OpenapiRuby
  class << self
    # Application root of whichever host framework is booted, used to resolve
    # the configured (relative) schema_output_dir. Falls back to the working
    # directory so schema generation works in a bare Ruby process — the
    # generation subprocess loads test files without booting an app.
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

    # True when Hanami is the host framework. Rails wins a tie: an app with
    # both constants loaded is a Rails app that happens to have hanami gems
    # in the bundle.
    def hanami_host?
      !!defined?(::Hanami) && !defined?(::Rails)
    end

    private

    def hanami_booted?
      defined?(::Hanami) && ::Hanami.respond_to?(:app?) && ::Hanami.app?
    end
  end
end
