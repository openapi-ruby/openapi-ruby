# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  gem "rake"
  gem "rspec-rails"
  gem "standard", ">= 1.35.1", require: false
  gem "standard-rspec", require: false
end

group :test do
  gem "minitest"
  gem "rack-test"
  gem "sorbet-runtime"
  rails_version = ENV.fetch("RAILS_VERSION", nil)
  if rails_version
    gem "rails", "~> #{rails_version}.0"
    if rails_version.to_f < 7.2
      gem "sqlite3", "~> 1.4"
    else
      gem "sqlite3"
    end
  else
    gem "rails", ">= 7.0"
    gem "sqlite3"
  end
end
