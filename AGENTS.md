# openapi_ruby

## Project Overview

A Ruby gem providing an OpenAPI 3.1 toolkit for Rails. Combines test-driven spec generation, reusable schema components, and runtime request/response validation middleware.

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

Key modules:

- `Core` — OpenAPI document model and builder
- `Components` — schema component system (Base, Loader, Registry, KeyTransformer). Component classes can be used directly as `$ref` shorthand in the DSL (e.g., `schema Schemas::User` instead of `schema "$ref" => "#/components/schemas/User"`). Classes also expose `.to_ref` for explicit ref generation.
- `DSL` — framework-agnostic test DSL (Context, OperationContext, ResponseContext, MetadataStore)
- `Adapters` — RSpec and Minitest adapters. RSpec supports two DSL styles: `path`/`run_test!` (schema and test interleaved) and `api_path`/`assert_api_response` (schema at top, normal specs below). Minitest uses the `api_path`/`assert_api_response` style.
- `Middleware` — Rack middleware for request/response validation
- `Testing` — request/response validators, assertions, coverage tracking
- `Generator` — OpenAPI spec file generation

## Testing

- Unit tests in `spec/openapi_ruby/`
- Generator tests in `spec/generators/`
- Integration tests in `spec/integration/` — these boot the dummy Rails app
- Dummy app in `spec/dummy/` — reference implementation with Users (RSpec `path`/`run_test!` style), Posts (Minitest and RSpec `api_path`/`assert_api_response` style)
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
- `railties >= 7.0`
- `rack >= 2.0`
