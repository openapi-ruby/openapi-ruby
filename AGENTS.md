# openapi_ruby

## Project Overview

A Ruby gem providing an OpenAPI 3.1 toolkit for Rails, Hanami, and plain Rack apps. Combines test-driven spec generation, reusable schema components, and runtime request/response validation middleware.

## Development

```bash
bundle install
bundle exec rspec          # run tests
bundle exec standardrb     # lint
```

## Architecture

Single gem with modular requires:

- `lib/openapi_ruby/` — core library
- `lib/openapi_ruby/rspec.rb` — require this for RSpec integration
- `lib/openapi_ruby/minitest.rb` — require this for Minitest integration
- `lib/openapi_ruby/hanami.rb` — require this on a Hanami host. Other Rack hosts (Sinatra, Roda) need no host file: they call `Middleware::Installer` and mount `RackApp` directly

Key modules:

- `Core` — OpenAPI document model and builder
- `Components` — schema component system (Base, Loader, Registry, KeyTransformer). Component classes can be used directly as `$ref` shorthand in the DSL (e.g., `schema Schemas::User` instead of `schema "$ref" => "#/components/schemas/User"`). Classes also expose `.to_ref` for explicit ref generation.
- `DSL` — framework-agnostic test DSL (Context, OperationContext, ResponseContext, MetadataStore)
- `Adapters` — RSpec and Minitest adapters. RSpec supports two DSL styles: `path`/`run_test!` (schema and test interleaved) and `api_path`/`assert_api_response` (schema at top, normal specs below). Minitest uses the `api_path`/`assert_api_response` style.
- `Middleware` — Rack middleware for request/response validation. `Middleware::Installer` mounts it onto any stack responding to `use` (Rails' `app.middleware`, Hanami's `config.middleware`), which is all the Engine initializer does now
- `Host` — `OpenapiRuby.app_root` and `.host` (`:rails` / `:hanami` / `:rack`, Rails winning a tie), the only places that ask which framework is booted
- `Serving` + `RackApp` — host-neutral schema/Swagger-UI serving. The Rails controllers under `app/controllers/` and `RackApp` (mounted directly on Hanami) are both thin shells over `Serving`
- `Testing` — request/response validators, assertions, coverage tracking. `Testing::Transport` is the seam between the adapters and the host's request API: Rails integration keywords (`params:`/`headers:`, `response`) vs rack-test positional args plus a Rack env (`last_response`). Both adapters auto-include `Rack::Test::Methods` on non-Rails hosts; only Hanami gets a default `app`
- `Generator` — OpenAPI spec file generation

## Testing

- Unit tests in `spec/openapi_ruby/`
- Generator tests in `spec/generators/`
- Integration tests in `spec/integration/` — these boot the dummy Rails app
- Dummy app in `spec/dummy/` — reference implementation with Users (RSpec `path`/`run_test!` style), Posts (Minitest and RSpec `api_path`/`assert_api_response` style)
- Alternate-host dummy apps, each in its own Rails-free bundle under `gemfiles/` — booting two frameworks in one process is not worth fighting, and the separate bundles also prove the gem loads without railties:
  - `spec/hanami_dummy/` — `rake spec:hanami`, `HANAMI_VERSION` selects the line (CI covers 2.3 and 3.0)
  - `spec/sinatra_dummy/` — `rake spec:sinatra`, `SINATRA_VERSION` selects the line (CI covers 3.2 and 4.2). Covers RSpec *and* Minitest, and mounts the docs endpoints through its real `config.ru`
  - `rake spec:hosts` runs both
- Each alternate host's CI job also regenerates its committed schema and fails on a diff — the middleware loads that document at boot, so a stale one silently stops exercising validation
- Dummy app specs live in `spec/dummy/spec/` and `spec/dummy/test/` exactly as a user would write them
- RSpec pattern excludes `spec/dummy/` from autodiscovery (see `.rspec`)

## Style

- Uses [standardrb](https://github.com/standardrb/standard)
- Double-quoted strings
- No trailing commas

## Commits

- Use [Conventional Commits](https://www.conventionalcommits.org/) — release-please generates the CHANGELOG from commit messages
- Prefix: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`

## Dependencies

- `json_schemer ~> 2.4` — sole validation engine (JSON Schema 2020-12 + OpenAPI 3.1)
- `activesupport >= 7.0`
- `rack >= 2.0`
- `railties` is deliberately *not* a runtime dependency — the Engine and generators load only when `Rails::Engine` is defined, so the gem installs into a Hanami app without Rails
