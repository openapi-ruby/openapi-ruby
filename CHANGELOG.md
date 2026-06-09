# Changelog

## [4.0.0](https://github.com/openapi-ruby/openapi-ruby/compare/v3.5.2...v4.0.0) (2026-06-09)


### ⚠ BREAKING CHANGES

* Configuration#schema_output_dir now defaults to "openapi" instead of "swagger". The Swagger name predates the 2016 rename to OpenAPI; the gem only supports OpenAPI 3.0/3.1, so the default should reflect that.
* Swagger UI is now served at the engine mount root instead of `<mount>/ui`. Update bookmarks and any links accordingly. The `config.ui_path` configuration option has been removed.

### Features

* default schema_output_dir to "openapi" ([#30](https://github.com/openapi-ruby/openapi-ruby/issues/30)) ([51c1a5b](https://github.com/openapi-ruby/openapi-ruby/commit/51c1a5b5004f8c22a6402a8fa86cd0f1524e0e74))
* serve Swagger UI at engine mount root ([#37](https://github.com/openapi-ruby/openapi-ruby/issues/37)) ([85e93d6](https://github.com/openapi-ruby/openapi-ruby/commit/85e93d6bd3c2fe263196e5fcbdc86decb7d2ce7e))

## [3.5.2](https://github.com/openapi-ruby/openapi-ruby/compare/v3.5.1...v3.5.2) (2026-06-09)


### Bug Fixes

* autoload Engine when Rails loads after openapi_ruby ([#35](https://github.com/openapi-ruby/openapi-ruby/issues/35)) ([d1cb8d9](https://github.com/openapi-ruby/openapi-ruby/commit/d1cb8d9b61491b489161a58e6abf121322aa21ac))

## [3.5.1](https://github.com/openapi-ruby/openapi-ruby/compare/v3.5.0...v3.5.1) (2026-06-09)


### Bug Fixes

* stable output and per-glob load paths in hybrid mode ([#33](https://github.com/openapi-ruby/openapi-ruby/issues/33)) ([763b7c7](https://github.com/openapi-ruby/openapi-ruby/commit/763b7c7bf452c2663404124abfbfb3614e146048))

## [3.5.0](https://github.com/openapi-ruby/openapi-ruby/compare/v3.4.0...v3.5.0) (2026-06-08)


### Features

* expose OpenapiRuby.schema_generating? helper ([#31](https://github.com/openapi-ruby/openapi-ruby/issues/31)) ([fc51f43](https://github.com/openapi-ruby/openapi-ruby/commit/fc51f436777c2b7a1f0c2aa4717f60d035a28c57))

## [3.4.0](https://github.com/openapi-ruby/openapi-ruby/compare/v3.3.0...v3.4.0) (2026-06-08)


### Features

* add FRAMEWORK=hybrid mode for migrations ([#28](https://github.com/openapi-ruby/openapi-ruby/issues/28)) ([5e77661](https://github.com/openapi-ruby/openapi-ruby/commit/5e77661f297e2736a0b5dd4787ec73b7ce14c8c0))

## [3.3.0](https://github.com/openapi-ruby/openapi-ruby/compare/v3.2.0...v3.3.0) (2026-05-22)


### Features

* support Ruby component classes as $ref shorthand ([#26](https://github.com/openapi-ruby/openapi-ruby/issues/26)) ([e4e51bf](https://github.com/openapi-ruby/openapi-ruby/commit/e4e51bfdbf45b9a3dbf7ef95ce8519c518b2418e))

## [3.2.0](https://github.com/openapi-ruby/openapi-ruby/compare/v3.1.1...v3.2.0) (2026-05-21)


### Features

* **rspec:** add minitest-style api_path / assert_api_response DSL ([ed106b3](https://github.com/openapi-ruby/openapi-ruby/commit/ed106b30801e1865f23ce6eb699547d69a6d35aa))
* validate requests against declared operations in test DSL ([2b35c0f](https://github.com/openapi-ruby/openapi-ruby/commit/2b35c0f10f0e1fadf4eff2f461e00f7375dd754f))


### Bug Fixes

* clean posts before users in spec teardown to avoid FK constraint ([8f2b425](https://github.com/openapi-ruby/openapi-ruby/commit/8f2b425b03e30d1559e150e3701f213e31717a8d))

## [3.1.1](https://github.com/openapi-ruby/openapi-ruby/compare/v3.1.0...v3.1.1) (2026-05-21)


### Bug Fixes

* always send query params in URL, not request body ([5e9f12a](https://github.com/openapi-ruby/openapi-ruby/commit/5e9f12a8436d66259f70a688b99e8020b3a1c44d))
* use Rack::Utils.build_nested_query for deep object query params ([8171661](https://github.com/openapi-ruby/openapi-ruby/commit/817166161aaa7e28706c975ca790d4491a82dba6))

## [3.1.0](https://github.com/openapi-ruby/openapi-ruby/compare/v3.0.3...v3.1.0) (2026-04-24)


### Features

* auto-load components on first query instead of requiring explicit load! ([2d371d3](https://github.com/openapi-ruby/openapi-ruby/commit/2d371d3e175b52aa8d34a23f338ba9a26a7f29cb))
* support array scope values in component_scope_paths, handle $ref params ([44d0736](https://github.com/openapi-ruby/openapi-ruby/commit/44d073675425dcdf86b1403afaf69983b69fef2c))


### Bug Fixes

* make component loading class-level to prevent duplicate load issues ([f4f3dd8](https://github.com/openapi-ruby/openapi-ruby/commit/f4f3dd8a985e758c7bbc6c663eeb5d65901248ef))
* only inject 400 response on operations with parameters or request body ([4a571eb](https://github.com/openapi-ruby/openapi-ruby/commit/4a571eb4752c87263d37bb7c36940cd63c750cf2))
* output path parameters at path level instead of copying to operations ([e8590d8](https://github.com/openapi-ruby/openapi-ruby/commit/e8590d888e51afec3dc9d8cc0c6066e754b54833))
* resolve $ref schemas in query param validation, fix path matching order, coerce deep object values ([33dfd16](https://github.com/openapi-ruby/openapi-ruby/commit/33dfd16ddefc5a8c731c22130006f7f99ba0d6e7))
* scope-specific components take precedence over shared on name collisions ([36f7676](https://github.com/openapi-ruby/openapi-ruby/commit/36f76767d7febfd9326034372bc0feed8e5626ec))
* skip middleware during schema generation ([0b437ae](https://github.com/openapi-ruby/openapi-ruby/commit/0b437ae35b6f211a9f6c0da3e6430df846811634))
* stop duplicating path params from adapter to operations ([75c8540](https://github.com/openapi-ruby/openapi-ruby/commit/75c85407a55fc3863551b690084b35cc98e79832))
* use instance flag for ensure_loaded instead of registry check ([9df828a](https://github.com/openapi-ruby/openapi-ruby/commit/9df828ae6117692cc8b6edd2a6e390db46e7d991))
* use Loader in SchemaWriter to ensure components are loaded in subprocess ([5b29714](https://github.com/openapi-ruby/openapi-ruby/commit/5b297148847af1ecf4f1e29a48793172a530c871))

## [3.0.3](https://github.com/openapi-ruby/openapi-ruby/compare/v3.0.2...v3.0.3) (2026-04-22)


### Bug Fixes

* correct cross-scope inheritance misattribution and deep-stringify nested keys ([7214e68](https://github.com/openapi-ruby/openapi-ruby/commit/7214e683a98d27753b6a33a24ee8d1a058ca7277))

## [3.0.2](https://github.com/openapi-ruby/openapi-ruby/compare/v3.0.1...v3.0.2) (2026-04-20)


### Bug Fixes

* default to RAILS_ENV=test by spawning subprocess for generation ([b1a7a8c](https://github.com/openapi-ruby/openapi-ruby/commit/b1a7a8c7bd92d967d01e1e141add09a2932dc90e))

## [3.0.1](https://github.com/openapi-ruby/openapi-ruby/compare/v3.0.0...v3.0.1) (2026-04-20)


### Bug Fixes

* deterministic schema output across platforms ([9699948](https://github.com/openapi-ruby/openapi-ruby/commit/9699948fb3fc8d8cf7328491489bef10647a3b5d))

## [3.0.0](https://github.com/openapi-ruby/openapi-ruby/compare/v2.6.1...v3.0.0) (2026-04-20)


### ⚠ BREAKING CHANGES

* Schema files are no longer written automatically after test suite runs. Use `rake openapi_ruby:generate` (or `bin/generate-schema`) to generate schemas explicitly. This prevents partial schema overwrites when running a subset of specs.

### Bug Fixes

* stop writing schemas during test runs, use require-based generation ([b16aba5](https://github.com/openapi-ruby/openapi-ruby/commit/b16aba57e0d8d9f7c99165942ed58efb0d26d68e))

## [2.6.1](https://github.com/openapi-ruby/openapi-ruby/compare/v2.6.0...v2.6.1) (2026-04-17)


### Bug Fixes

* always include top-level security array in generated schemas ([3fb6250](https://github.com/openapi-ruby/openapi-ruby/commit/3fb625017302994e846fa430a5f80da0e1641102))
* prevent duplicate parameters from path-level + operation-level ([feb15df](https://github.com/openapi-ruby/openapi-ruby/commit/feb15df537cc61b4265548c1382b6f8628ef26e5))

## [2.6.0](https://github.com/openapi-ruby/openapi-ruby/compare/v2.5.2...v2.6.0) (2026-04-17)


### Features

* support OpenAPI 3.0.x schemas ([caa831b](https://github.com/openapi-ruby/openapi-ruby/commit/caa831b7c2ab6d6101e371dbd92b009b471bac68))


### Bug Fixes

* use component_scope from schema config for security scheme resolution ([a49854b](https://github.com/openapi-ruby/openapi-ruby/commit/a49854b3e45f9fc403fd3e124ee4929ba01e7fae))

## [2.5.2](https://github.com/openapi-ruby/openapi-ruby/compare/v2.5.1...v2.5.2) (2026-04-17)


### Bug Fixes

* keep first visible response when duplicate status codes exist ([f434914](https://github.com/openapi-ruby/openapi-ruby/commit/f434914e9d073cbfe7ddfd5674cc0043294b7429))

## [2.5.1](https://github.com/openapi-ruby/openapi-ruby/compare/v2.5.0...v2.5.1) (2026-04-17)


### Bug Fixes

* hidden responses overwriting visible ones with same status code ([437a1d6](https://github.com/openapi-ruby/openapi-ruby/commit/437a1d620ddd54883a5fb79a628940261bfc90e6))

## [2.5.0](https://github.com/openapi-ruby/openapi-ruby/compare/v2.4.0...v2.5.0) (2026-04-17)


### Features

* support both RSpec and Minitest in rake task ([4cbd0ac](https://github.com/openapi-ruby/openapi-ruby/commit/4cbd0ac836b2929664970fc326bbbc3876405713))


### Bug Fixes

* component scoping with Rails autoloading and unscoped components ([25efff6](https://github.com/openapi-ruby/openapi-ruby/commit/25efff67c637a034fa2cf05d734d28d79cfdbcd8))
* resolve Accept header from let variable, support custom Accept ([80de102](https://github.com/openapi-ruby/openapi-ruby/commit/80de102be010974f44bc86384f7ef98bf2671f41))
* schema generation with RSpec --dry-run mode ([6aa1d66](https://github.com/openapi-ruby/openapi-ruby/commit/6aa1d66cab5bff2937f4b1f8478ce5fa5b37fbfb))

## [2.4.0](https://github.com/openapi-ruby/openapi-ruby/compare/v2.3.1...v2.4.0) (2026-04-16)


### Features

* base path resolution and nested context support for run_test! ([6d0ad17](https://github.com/openapi-ruby/openapi-ruby/commit/6d0ad17aad13a6a7f77f76cc39d1a8a19dce388e))
* rake task for schema generation via rspec --dry-run ([bd89b10](https://github.com/openapi-ruby/openapi-ruby/commit/bd89b10ce1e2f5d88627eb9812e53a30eee08499))
* resolve base path from schema server URL in RSpec adapter ([ba818af](https://github.com/openapi-ruby/openapi-ruby/commit/ba818af45ff49c61224bd7bb3aa81966f7d183d4))
* update minitest adapter with feature parity to RSpec adapter ([fccc0d2](https://github.com/openapi-ruby/openapi-ruby/commit/fccc0d26608fe6cd51e6bc60a9c104b5bca44cb6))


### Bug Fixes

* security scheme resolution, falsy params, and query params with body ([813ba2b](https://github.com/openapi-ruby/openapi-ruby/commit/813ba2b8c5dc0b50c43616f52d3bbbf8e0b7f33c))

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
