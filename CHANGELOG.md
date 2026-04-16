# Changelog

## [2.3.1](https://github.com/openapi-ruby/openapi-ruby/compare/v2.3.0...v2.3.1) (2026-04-16)


### Bug Fixes

* allow same-named components during initial loading before scope assignment ([49b1d82](https://github.com/openapi-ruby/openapi-ruby/commit/49b1d82e9959c2f1549d05c38024ea2a6101fcce))
* only check for duplicates when both sides have explicitly set their scopes. ([49b1d82](https://github.com/openapi-ruby/openapi-ruby/commit/49b1d82e9959c2f1549d05c38024ea2a6101fcce))
* update duplicate detection test to use explicit scopes ([f081f8d](https://github.com/openapi-ruby/openapi-ruby/commit/f081f8d4cfaa9923d84da1281be1f5dc3e9933e2))

## [2.3.0](https://github.com/openapi-ruby/openapi-ruby/compare/v2.2.1...v2.3.0) (2026-04-16)


### Features

* request_body schema shorthand and hidden responses ([032f5b0](https://github.com/openapi-ruby/openapi-ruby/commit/032f5b0ab322071190b55bb9688e939445f84b3d))

## [2.2.1](https://github.com/openapi-ruby/openapi-ruby/compare/v2.2.0...v2.2.1) (2026-04-16)


### Bug Fixes

* require matching scope-configuration state for duplicate detection ([78c3146](https://github.com/openapi-ruby/openapi-ruby/commit/78c31462a4c026f554737cf38946cee3646399ff))

## [2.2.0](https://github.com/openapi-ruby/openapi-ruby/compare/v2.1.0...v2.2.0) (2026-04-16)


### Features

* improve component loading, schema inheritance, and Swagger UI ([9de585d](https://github.com/openapi-ruby/openapi-ruby/commit/9de585d607d956b384e1100b459864852b3b8602))


### Bug Fixes

* add duplicate component detection to registry ([cb7f99a](https://github.com/openapi-ruby/openapi-ruby/commit/cb7f99a7860efccd98ca4d810141cd903581c279))

## [2.1.0](https://github.com/openapi-ruby/openapi-ruby/compare/v2.0.0...v2.1.0) (2026-04-16)


### Features

* add multi-schema Swagger UI, glob routes, and OAuth2 redirect ([0cd07b8](https://github.com/openapi-ruby/openapi-ruby/commit/0cd07b87033a6e1f59039bc78e859472c6175dce))


### Bug Fixes

* resolve standardrb linting violation in ui_controller ([a2b3a0f](https://github.com/openapi-ruby/openapi-ruby/commit/a2b3a0f120fb9da5a89ec7011c4971ca6045f612))

## [2.0.0](https://github.com/openapi-ruby/openapi-ruby/compare/v1.0.1...v2.0.0) (2026-04-16)


### ⚠ BREAKING CHANGES

* gem name, module name, and all require paths changed.

### Features

* add integration features for multi-schema projects ([a2b866c](https://github.com/openapi-ruby/openapi-ruby/commit/a2b866c9bf4dbb52d6cb398dc5767039775c10f6))
* add RubyGems publish step to release workflow ([8a46ad9](https://github.com/openapi-ruby/openapi-ruby/commit/8a46ad98ae80cff0ba8e753bb990a1a1ffd9f4fb))
* auto-inject 400 ValidationError response into generated specs ([1a7b1d4](https://github.com/openapi-ruby/openapi-ruby/commit/1a7b1d4215fc46aa1bc3db3fd74219cee1636145))


### Bug Fixes

* disable component prefix in release-please tags ([fcce8d0](https://github.com/openapi-ruby/openapi-ruby/commit/fcce8d0ac06ce55801a2d6196db9a49bdfd26aa6))
* pin rubygems/configure-rubygems-credentials to v1.0.0 ([9dd7b08](https://github.com/openapi-ruby/openapi-ruby/commit/9dd7b08d577f02012fa4c9aecd7391c65ed778cc))
* pin sqlite3 ~&gt; 1.4 for Rails 7.0/7.1 in CI ([845f8d0](https://github.com/openapi-ruby/openapi-ruby/commit/845f8d0056b5c540e2b07ca16ca6e1f5bc795c9c))
* resolve heredoc indentation lint error in loader spec ([16c17cd](https://github.com/openapi-ruby/openapi-ruby/commit/16c17cd04ae7da38f650a8d11fa8fdeabd86c244))
* switch back to RubyGems trusted publisher for CI publishing ([5433d2d](https://github.com/openapi-ruby/openapi-ruby/commit/5433d2dae9b23edd96f4aeb69dd0a03ac7a4ccf8))
* use API key credentials file for RubyGems push ([90703ac](https://github.com/openapi-ruby/openapi-ruby/commit/90703ac29b07721fd7e2a8b71e4a408244f4b9bc))
* use PAT for release-please to create PRs ([149912a](https://github.com/openapi-ruby/openapi-ruby/commit/149912a7cd6c18496e20d3a7b2c992f0a2f350de))
* use release-please manifest config and RubyGems trusted publisher ([da29c0e](https://github.com/openapi-ruby/openapi-ruby/commit/da29c0e1725d2339bdade9fad038ac0d8f5dbd7e))


### Code Refactoring

* rename gem from openapi_rails to openapi-ruby ([2050234](https://github.com/openapi-ruby/openapi-ruby/commit/20502344e57b92d0893151c296a61d37893f8ad0))

## [1.0.1](https://github.com/openapi-ruby/openapi-ruby/compare/openapi-ruby/v1.0.0...openapi-ruby/v1.0.1) (2026-04-16)


### Bug Fixes

* pin rubygems/configure-rubygems-credentials to v1.0.0 ([9dd7b08](https://github.com/openapi-ruby/openapi-ruby/commit/9dd7b08d577f02012fa4c9aecd7391c65ed778cc))

## [1.0.0](https://github.com/openapi-ruby/openapi-ruby/compare/openapi-ruby-v0.1.0...openapi-ruby/v1.0.0) (2026-04-16)


### ⚠ BREAKING CHANGES

* gem name, module name, and all require paths changed.

### Features

* add integration features for multi-schema projects ([a2b866c](https://github.com/openapi-ruby/openapi-ruby/commit/a2b866c9bf4dbb52d6cb398dc5767039775c10f6))
* add RubyGems publish step to release workflow ([8a46ad9](https://github.com/openapi-ruby/openapi-ruby/commit/8a46ad98ae80cff0ba8e753bb990a1a1ffd9f4fb))
* auto-inject 400 ValidationError response into generated specs ([1a7b1d4](https://github.com/openapi-ruby/openapi-ruby/commit/1a7b1d4215fc46aa1bc3db3fd74219cee1636145))


### Bug Fixes

* pin sqlite3 ~&gt; 1.4 for Rails 7.0/7.1 in CI ([845f8d0](https://github.com/openapi-ruby/openapi-ruby/commit/845f8d0056b5c540e2b07ca16ca6e1f5bc795c9c))
* resolve heredoc indentation lint error in loader spec ([16c17cd](https://github.com/openapi-ruby/openapi-ruby/commit/16c17cd04ae7da38f650a8d11fa8fdeabd86c244))
* switch back to RubyGems trusted publisher for CI publishing ([5433d2d](https://github.com/openapi-ruby/openapi-ruby/commit/5433d2dae9b23edd96f4aeb69dd0a03ac7a4ccf8))
* use API key credentials file for RubyGems push ([90703ac](https://github.com/openapi-ruby/openapi-ruby/commit/90703ac29b07721fd7e2a8b71e4a408244f4b9bc))
* use PAT for release-please to create PRs ([149912a](https://github.com/openapi-ruby/openapi-ruby/commit/149912a7cd6c18496e20d3a7b2c992f0a2f350de))
* use release-please manifest config and RubyGems trusted publisher ([da29c0e](https://github.com/openapi-ruby/openapi-ruby/commit/da29c0e1725d2339bdade9fad038ac0d8f5dbd7e))


### Code Refactoring

* rename gem from openapi_rails to openapi-ruby ([2050234](https://github.com/openapi-ruby/openapi-ruby/commit/20502344e57b92d0893151c296a61d37893f8ad0))

## 1.0.0 (2026-04-15)


### Features

* add RubyGems publish step to release workflow ([8a46ad9](https://github.com/openapi-ruby/openapi-ruby/commit/8a46ad98ae80cff0ba8e753bb990a1a1ffd9f4fb))


### Bug Fixes

* pin sqlite3 ~&gt; 1.4 for Rails 7.0/7.1 in CI ([845f8d0](https://github.com/openapi-ruby/openapi-ruby/commit/845f8d0056b5c540e2b07ca16ca6e1f5bc795c9c))
* use PAT for release-please to create PRs ([149912a](https://github.com/openapi-ruby/openapi-ruby/commit/149912a7cd6c18496e20d3a7b2c992f0a2f350de))
