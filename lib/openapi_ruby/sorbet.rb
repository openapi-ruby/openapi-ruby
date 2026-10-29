# frozen_string_literal: true

require "openapi_ruby"

begin
  require "sorbet-runtime"
rescue LoadError
  raise LoadError, "openapi_ruby/sorbet requires the sorbet-runtime gem. Add `gem \"sorbet-runtime\"` to your Gemfile."
end

require_relative "components/typed_params"
