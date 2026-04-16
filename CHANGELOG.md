# Changelog

## [2.0.0](https://github.com/mortik/openapi-ruby/compare/v1.0.1...v2.0.0) (2026-04-16)


### ⚠ BREAKING CHANGES

* gem name, module name, and all require paths changed.

### Features

* add integration features for multi-schema projects ([a2b866c](https://github.com/mortik/openapi-ruby/commit/a2b866c9bf4dbb52d6cb398dc5767039775c10f6))
* add RubyGems publish step to release workflow ([8a46ad9](https://github.com/mortik/openapi-ruby/commit/8a46ad98ae80cff0ba8e753bb990a1a1ffd9f4fb))
* auto-inject 400 ValidationError response into generated specs ([1a7b1d4](https://github.com/mortik/openapi-ruby/commit/1a7b1d4215fc46aa1bc3db3fd74219cee1636145))


### Bug Fixes

* disable component prefix in release-please tags ([fcce8d0](https://github.com/mortik/openapi-ruby/commit/fcce8d0ac06ce55801a2d6196db9a49bdfd26aa6))
* pin rubygems/configure-rubygems-credentials to v1.0.0 ([9dd7b08](https://github.com/mortik/openapi-ruby/commit/9dd7b08d577f02012fa4c9aecd7391c65ed778cc))
* pin sqlite3 ~&gt; 1.4 for Rails 7.0/7.1 in CI ([845f8d0](https://github.com/mortik/openapi-ruby/commit/845f8d0056b5c540e2b07ca16ca6e1f5bc795c9c))
* resolve heredoc indentation lint error in loader spec ([16c17cd](https://github.com/mortik/openapi-ruby/commit/16c17cd04ae7da38f650a8d11fa8fdeabd86c244))
* switch back to RubyGems trusted publisher for CI publishing ([5433d2d](https://github.com/mortik/openapi-ruby/commit/5433d2dae9b23edd96f4aeb69dd0a03ac7a4ccf8))
* use API key credentials file for RubyGems push ([90703ac](https://github.com/mortik/openapi-ruby/commit/90703ac29b07721fd7e2a8b71e4a408244f4b9bc))
* use PAT for release-please to create PRs ([149912a](https://github.com/mortik/openapi-ruby/commit/149912a7cd6c18496e20d3a7b2c992f0a2f350de))
* use release-please manifest config and RubyGems trusted publisher ([da29c0e](https://github.com/mortik/openapi-ruby/commit/da29c0e1725d2339bdade9fad038ac0d8f5dbd7e))


### Code Refactoring

* rename gem from openapi_rails to openapi-ruby ([2050234](https://github.com/mortik/openapi-ruby/commit/20502344e57b92d0893151c296a61d37893f8ad0))

## [1.0.1](https://github.com/mortik/openapi-ruby/compare/openapi-ruby/v1.0.0...openapi-ruby/v1.0.1) (2026-04-16)


### Bug Fixes

* pin rubygems/configure-rubygems-credentials to v1.0.0 ([9dd7b08](https://github.com/mortik/openapi-ruby/commit/9dd7b08d577f02012fa4c9aecd7391c65ed778cc))

## [1.0.0](https://github.com/mortik/openapi-ruby/compare/openapi-ruby-v0.1.0...openapi-ruby/v1.0.0) (2026-04-16)


### ⚠ BREAKING CHANGES

* gem name, module name, and all require paths changed.

### Features

* add integration features for multi-schema projects ([a2b866c](https://github.com/mortik/openapi-ruby/commit/a2b866c9bf4dbb52d6cb398dc5767039775c10f6))
* add RubyGems publish step to release workflow ([8a46ad9](https://github.com/mortik/openapi-ruby/commit/8a46ad98ae80cff0ba8e753bb990a1a1ffd9f4fb))
* auto-inject 400 ValidationError response into generated specs ([1a7b1d4](https://github.com/mortik/openapi-ruby/commit/1a7b1d4215fc46aa1bc3db3fd74219cee1636145))


### Bug Fixes

* pin sqlite3 ~&gt; 1.4 for Rails 7.0/7.1 in CI ([845f8d0](https://github.com/mortik/openapi-ruby/commit/845f8d0056b5c540e2b07ca16ca6e1f5bc795c9c))
* resolve heredoc indentation lint error in loader spec ([16c17cd](https://github.com/mortik/openapi-ruby/commit/16c17cd04ae7da38f650a8d11fa8fdeabd86c244))
* switch back to RubyGems trusted publisher for CI publishing ([5433d2d](https://github.com/mortik/openapi-ruby/commit/5433d2dae9b23edd96f4aeb69dd0a03ac7a4ccf8))
* use API key credentials file for RubyGems push ([90703ac](https://github.com/mortik/openapi-ruby/commit/90703ac29b07721fd7e2a8b71e4a408244f4b9bc))
* use PAT for release-please to create PRs ([149912a](https://github.com/mortik/openapi-ruby/commit/149912a7cd6c18496e20d3a7b2c992f0a2f350de))
* use release-please manifest config and RubyGems trusted publisher ([da29c0e](https://github.com/mortik/openapi-ruby/commit/da29c0e1725d2339bdade9fad038ac0d8f5dbd7e))


### Code Refactoring

* rename gem from openapi_rails to openapi-ruby ([2050234](https://github.com/mortik/openapi-ruby/commit/20502344e57b92d0893151c296a61d37893f8ad0))

## 1.0.0 (2026-04-15)


### Features

* add RubyGems publish step to release workflow ([8a46ad9](https://github.com/mortik/openapi_ruby/commit/8a46ad98ae80cff0ba8e753bb990a1a1ffd9f4fb))


### Bug Fixes

* pin sqlite3 ~&gt; 1.4 for Rails 7.0/7.1 in CI ([845f8d0](https://github.com/mortik/openapi_ruby/commit/845f8d0056b5c540e2b07ca16ca6e1f5bc795c9c))
* use PAT for release-please to create PRs ([149912a](https://github.com/mortik/openapi_ruby/commit/149912a7cd6c18496e20d3a7b2c992f0a2f350de))
