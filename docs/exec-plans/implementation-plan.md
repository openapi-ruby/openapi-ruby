# openapi_rails — Implementation Plan

## Context

**Problem:** rswag is under-maintained ("Seeking maintainers!"), tightly coupled to RSpec, stuck on OpenAPI 3.0 (no 3.1), uses the outdated `json-schema` gem (Draft 4 only), and lacks runtime request/response validation. Users wanting reusable schema components must bolt on `rswag-schema-components`. Users wanting middleware validation must use `committee` separately with a completely different workflow.

**Goal:** Build `openapi_rails` — a single gem that unifies all three projects' capabilities: test-driven OpenAPI spec generation (rswag), reusable schema components as Ruby classes (rswag-schema-components), and runtime request/response validation middleware (committee). It must be test-framework agnostic (RSpec + Minitest), support OpenAPI 3.1, and use modern JSON Schema validation.

---

## 1. Gem Structure — Single Gem, Modular Requires

**Single gem, not sub-gems.** Rswag's sub-gem approach causes version-skew bugs and confusing installs. Instead: one gem with optional requires so users load only what they need.

```
openapi_rails/
├── openapi_rails.gemspec
├── Gemfile
├── Rakefile
├── LICENSE
├── README.md
├── lib/
│   ├── openapi_rails.rb                        # Root: config, autoloads
│   ├── openapi_rails/
│   │   ├── version.rb
│   │   ├── configuration.rb
│   │   ├── errors.rb
│   │   │
│   │   ├── core/                               # OpenAPI document model
│   │   │   ├── document.rb                     # In-memory OA 3.1 document
│   │   │   ├── document_builder.rb             # Merges DSL defs + components
│   │   │   ├── path_item.rb
│   │   │   ├── operation.rb
│   │   │   ├── parameter.rb
│   │   │   ├── request_body.rb
│   │   │   ├── response.rb
│   │   │   ├── media_type.rb
│   │   │   └── ref_resolver.rb                 # $ref helper
│   │   │
│   │   ├── components/                         # Schema component system
│   │   │   ├── base.rb                         # Mixin with DSL
│   │   │   ├── loader.rb                       # Directory discovery + loading
│   │   │   ├── registry.rb                     # Global component registry
│   │   │   └── key_transformer.rb              # snake_case -> camelCase
│   │   │
│   │   ├── dsl/                                # Test DSL (framework-agnostic)
│   │   │   ├── context.rb                      # Holds state for one path
│   │   │   ├── operation_context.rb            # State for one HTTP method
│   │   │   ├── response_context.rb             # State for one response
│   │   │   ├── parameter_dsl.rb
│   │   │   ├── request_body_dsl.rb
│   │   │   ├── security_dsl.rb
│   │   │   └── metadata_store.rb               # Collects all DSL definitions
│   │   │
│   │   ├── adapters/                           # Test framework adapters
│   │   │   ├── base.rb                         # Abstract interface
│   │   │   ├── rspec.rb                        # RSpec integration
│   │   │   └── minitest.rb                     # Minitest integration
│   │   │
│   │   ├── middleware/                          # Runtime validation (Rack)
│   │   │   ├── request_validation.rb
│   │   │   ├── response_validation.rb
│   │   │   ├── coercion.rb                     # Type coercion
│   │   │   ├── error_handler.rb
│   │   │   ├── path_matcher.rb                 # /users/{id} -> regex
│   │   │   └── schema_resolver.rb              # Loads & caches OA doc
│   │   │
│   │   ├── testing/                            # Shared test helpers
│   │   │   ├── assertions.rb                   # assert_schema_conform etc.
│   │   │   ├── request_builder.rb              # Builds Rack request from DSL
│   │   │   ├── response_validator.rb           # Validates response vs schema
│   │   │   ├── coverage.rb                     # Endpoint coverage tracking
│   │   │   └── coverage_reporter.rb
│   │   │
│   │   ├── generator/                          # OpenAPI spec file output
│   │   │   ├── spec_writer.rb                  # Writes JSON/YAML from metadata
│   │   │   ├── json_formatter.rb
│   │   │   └── yaml_formatter.rb
│   │   │
│   │   ├── ui/                                 # Swagger UI serving (optional)
│   │   │   ├── engine.rb                       # Rails engine
│   │   │   └── configuration.rb
│   │   │
│   │   ├── engine.rb                           # Main Rails engine
│   │   └── railtie.rb
│   │
│   └── generators/openapi_rails/
│       ├── install/
│       │   ├── install_generator.rb
│       │   └── templates/
│       │       ├── initializer.rb.tt
│       │       └── openapi_helper.rb.tt
│       └── component/
│           ├── component_generator.rb
│           └── templates/
│               └── component.rb.tt
│
├── app/
│   └── controllers/openapi_rails/
│       ├── specs_controller.rb                 # Serves OA spec as JSON/YAML
│       └── ui_controller.rb                    # Serves Swagger UI HTML
│
├── config/
│   └── routes.rb                               # Engine routes
│
├── spec/                                       # Gem tests (RSpec)
└── test/                                       # Gem tests (Minitest)
```

---

## 2. Dependencies

```ruby
# openapi_rails.gemspec
s.add_dependency 'json_schemer', '~> 2.4'     # JSON Schema 2020-12 + OA 3.1
s.add_dependency 'rack', '>= 2.0'
s.add_dependency 'railties', '>= 7.0'
s.add_dependency 'activesupport', '>= 7.0'

# Swagger UI is optional — only needed if config.ui_enabled = true
# Users install swagger-ui-dist themselves or use CDN mode (no extra gem)

s.add_development_dependency 'rspec-rails'
s.add_development_dependency 'minitest'
s.add_development_dependency 'rake'
s.add_development_dependency 'rubocop'
```

**Key decision: `json_schemer` as the sole validation engine.** It natively supports JSON Schema 2020-12 and OpenAPI 3.1 — replacing both `json-schema` (rswag, Draft 4 only) and `openapi_parser` (committee). `JSONSchemer.openapi(document)` parses a full OA document, resolves `$ref`, and validates schemas including `readOnly`/`writeOnly` support.

---

## 3. Configuration System

```ruby
OpenapiRails.configure do |config|
  # Spec definitions (supports multiple: public, admin, internal)
  config.specs = {
    public_api: {
      info: { title: 'Public API', version: 'v1' },
      servers: [{ url: 'https://api.example.com' }],
      component_scope: :public
    }
  }

  # Components
  config.component_paths = ['app/api_components']
  config.camelize_keys = true                    # snake_case -> camelCase

  # Middleware (runtime validation)
  config.request_validation = :disabled          # :enabled, :disabled, :warn_only
  config.response_validation = :disabled
  config.strict_mode = false                     # 404 for undocumented paths
  config.coerce_params = true                    # string -> int/bool/datetime
  config.error_handler = nil                     # Proc for custom error rendering

  # Test / Generation
  config.spec_output_dir = 'swagger'
  config.spec_output_format = :yaml              # :yaml or :json
  config.validate_responses_in_tests = true

  # UI (optional — disabled by default)
  config.ui_enabled = false
  config.ui_path = '/api-docs'
  config.ui_config = {}                          # Swagger UI config hash

  # Coverage
  config.coverage_enabled = false
  config.coverage_report_path = 'tmp/openapi_coverage.json'
end
```

---

## 4. Test Framework Adapter Pattern

The DSL core is pure Ruby with zero framework dependencies. Thin adapter layers bridge to RSpec/Minitest.

### Architecture

```
┌─────────────────────────────────┐
│     DSL Core (pure Ruby)        │
│  Context, OperationContext,     │
│  ResponseContext, MetadataStore │
└──────────┬──────────┬───────────┘
           │          │
    ┌──────▼──┐  ┌────▼─────┐
    │  RSpec  │  │ Minitest │
    │ Adapter │  │ Adapter  │
    └─────────┘  └──────────┘
```

### Adapter Interface (abstract)

```ruby
module OpenapiRails::Adapters::Base
  def install!              # Register DSL with the framework
  def resolve_params        # Read test params (let blocks / instance vars)
  def execute_request(...)  # Dispatch HTTP request
  def last_response         # Get response from last request
  def register_after_suite  # Hook for spec generation after all tests
end
```

### RSpec Adapter — registers via `RSpec.configure`, uses `describe`/`it`/`let`, generates test cases from DSL blocks, runs spec generation in `after(:suite)`.

### Minitest Adapter — provides `include OpenapiRails::Minitest::DSL` mixin, uses `test_*` methods and instance variables, runs spec generation via `Minitest.after_run`.

---

## 5. User-Facing DSL

### RSpec Usage

```ruby
# spec/requests/users_spec.rb
require 'openapi_rails/rspec'

RSpec.describe 'Users API', type: :openapi do
  path '/api/v1/users' do
    get 'List users' do
      tags 'Users'
      produces 'application/json'
      parameter name: :page, in: :query, schema: { type: :integer }, required: false

      response 200, 'successful' do
        schema type: :array, items: { '$ref' => '#/components/schemas/User' }

        let(:page) { 1 }
        run_test!
      end

      response 401, 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end

    post 'Create a user' do
      tags 'Users'
      consumes 'application/json'

      request_body required: true, content: {
        'application/json' => {
          schema: { '$ref' => '#/components/schemas/UserInput' }
        }
      }

      response 201, 'created' do
        schema '$ref' => '#/components/schemas/User'
        let(:request_body) { { name: 'Jane', email: 'jane@example.com' } }
        run_test!
      end

      response 422, 'validation error' do
        schema '$ref' => '#/components/schemas/ValidationErrors'
        let(:request_body) { { name: '' } }
        run_test!
      end
    end
  end

  path '/api/v1/users/{id}' do
    parameter name: :id, in: :path, schema: { type: :integer }, required: true

    get 'Get a user' do
      tags 'Users'

      response 200, 'found' do
        schema '$ref' => '#/components/schemas/User'
        let(:id) { create(:user).id }
        run_test!
      end

      response 404, 'not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
```

### Minitest Usage

```ruby
# test/integration/users_test.rb
require 'openapi_rails/minitest'

class UsersApiTest < ActionDispatch::IntegrationTest
  include OpenapiRails::Minitest::DSL

  openapi_spec :public_api  # which spec this test contributes to

  api_path '/api/v1/users' do
    get 'List users' do
      tags 'Users'
      produces 'application/json'
      parameter name: :page, in: :query, schema: { type: :integer }

      response 200, 'successful' do
        schema type: :array, items: { '$ref' => '#/components/schemas/User' }
      end
    end

    post 'Create a user' do
      tags 'Users'
      consumes 'application/json'

      request_body required: true, content: {
        'application/json' => {
          schema: { '$ref' => '#/components/schemas/UserInput' }
        }
      }

      response 201, 'created' do
        schema '$ref' => '#/components/schemas/User'
      end

      response 422, 'validation error' do
        schema '$ref' => '#/components/schemas/ValidationErrors'
      end
    end
  end

  test 'GET /api/v1/users returns paginated list' do
    test_response :get, 200, params: { page: 1 } do
      assert_equal 25, parsed_body.length
    end
  end

  test 'POST /api/v1/users creates user' do
    test_response :post, 201, body: { name: 'Jane', email: 'jane@example.com' } do
      assert_equal 'Jane', parsed_body['name']
    end
  end

  test 'POST /api/v1/users with invalid data returns 422' do
    test_response :post, 422, body: { name: '' }
  end
end
```

### DSL Methods Reference

| Method | Level | Description |
|--------|-------|-------------|
| `path(template, &block)` | Top | Define an API path |
| `get/post/put/patch/delete/head/options(summary, &block)` | Path | Define an operation |
| `tags(*tags)` | Operation | Tag the operation |
| `operationId(id)` | Operation | Set operation ID |
| `description(text)` | Operation | Operation description |
| `deprecated(bool)` | Operation | Mark as deprecated |
| `consumes(*types)` | Operation | Request content types |
| `produces(*types)` | Operation | Response content types |
| `security(schemes)` | Operation | Security requirements |
| `parameter(name:, in:, schema:, **opts)` | Path/Operation | Define a parameter |
| `request_body(required:, content:)` | Operation | Define request body (OA 3.x style) |
| `response(status, description, &block)` | Operation | Define expected response |
| `schema(definition)` | Response | Response body schema |
| `header(name, schema:, **opts)` | Response | Response header |
| `example(mime, name:, value:)` | Response | Response example |
| `request_body_example(value:, name:)` | Operation | Request body example |
| `run_test!(&block)` | Response | Execute request and validate (RSpec) |

---

## 6. Schema Component System

### Defining Components

```ruby
# app/api_components/schemas/base_model.rb
class Schemas::BaseModel
  include OpenapiRails::Components::Base

  schema(
    type: :object,
    properties: {
      id: { type: :integer, readOnly: true },
      created_at: { type: :string, format: 'date-time', readOnly: true },
      updated_at: { type: :string, format: 'date-time', readOnly: true }
    }
  )
end

# app/api_components/schemas/user.rb
class Schemas::User < Schemas::BaseModel
  # Inherits id, created_at, updated_at via deep merge
  schema(
    properties: {
      name: { type: :string },
      email: { type: :string, format: :email }
    },
    required: %i[name email]
  )
end

# app/api_components/schemas/user_input.rb
class Schemas::UserInput
  include OpenapiRails::Components::Base

  schema(
    type: :object,
    properties: {
      name: { type: :string, minLength: 1 },
      email: { type: :string, format: :email }
    },
    required: %i[name email]
  )
end

# app/api_components/security_schemes/bearer_auth.rb
class SecuritySchemes::BearerAuth
  include OpenapiRails::Components::Base
  component_type :security_schemes

  schema(
    type: :http,
    scheme: :bearer,
    bearerFormat: 'JWT'
  )
end
```

### Component DSL Methods

| Method | Description |
|--------|-------------|
| `schema(hash)` | Define the OpenAPI schema. Deep-merges with parent on inheritance. |
| `schema_hidden(true)` | Exclude from output (still available for inheritance) |
| `skip_key_transformation(true)` | Disable camelCase conversion for this component |
| `component_type(:schemas)` | Set component type (schemas, parameters, securitySchemes, requestBodies, responses, headers, examples, links, callbacks) |

### Loader

- Auto-discovers component files from `config.component_paths` directories
- Supports scoped loading for multiple API specs (public, admin, shared)
- Supports packs/packwerk directories
- Detects duplicate component names and raises errors
- Injects `title` for schema components automatically
- Outputs a hash suitable for `components:` in the OpenAPI document

---

## 7. Middleware — Runtime Validation

### Request Validation

```ruby
# Rack middleware — validates incoming requests against the OpenAPI spec

# config/initializers/openapi_rails.rb
OpenapiRails.configure do |config|
  config.request_validation = :enabled       # or :warn_only, :disabled
  config.strict_mode = true                  # 404 for undocumented paths
  config.strict_query_params = true          # reject unknown query params
  config.coerce_params = true                # "42" -> 42 for integer params
end
```

**What it validates:**
- Required parameters present (path, query, header)
- Parameter types match schema (with optional coercion)
- Request body matches schema and content type
- Unknown query params rejected (strict mode)
- Undocumented paths return 404 (strict mode)

**Error responses:** Configurable via `error_handler` proc. Default returns JSON `{ error: "...", details: [...] }` with 400/404 status.

### Response Validation

```ruby
config.response_validation = :enabled        # or :warn_only, :disabled
```

**What it validates:**
- Response status code is documented for the operation
- Response body matches the schema for that status code
- Response headers match if documented

**On failure:** Returns 500 (server produced invalid response) or logs warning in `:warn_only` mode. Configurable via `error_handler`.

### Path Matching

Custom regexp-based matcher converts OpenAPI path templates (`/users/{id}/posts/{post_id}`) to named capture groups. Cached on first load.

---

## 8. Test Helpers — Assertion-Based Validation (Committee-style)

For users who prefer schema-first (write the spec, then validate against it):

```ruby
# RSpec
require 'openapi_rails/rspec'

RSpec.describe 'Users API', type: :request do
  include OpenapiRails::Testing::Assertions

  it 'conforms to schema' do
    get '/api/v1/users', params: { page: 1 }
    assert_response_schema_conform(200)     # validates response vs spec
  end

  it 'validates request too' do
    post '/api/v1/users', params: { name: 'Jane' }.to_json,
         headers: { 'Content-Type' => 'application/json' }
    assert_request_schema_conform             # validates request was valid
    assert_response_schema_conform(201)
  end
end

# Minitest
class UsersApiTest < ActionDispatch::IntegrationTest
  include OpenapiRails::Testing::Assertions

  test 'conforms to schema' do
    get '/api/v1/users', params: { page: 1 }
    assert_response_schema_conform(200)
  end
end
```

### Schema Coverage

```ruby
OpenapiRails.configure do |config|
  config.coverage_enabled = true
  config.coverage_report_path = 'tmp/openapi_coverage.json'
end
```

Tracks which path/method/status-code combinations are exercised by tests. Reports uncovered endpoints after the test suite.

---

## 9. OpenAPI Generation Pipeline

Two workflows, both first-class:

### Workflow A: Generate from tests (rswag-style)

Tests define API structure via DSL -> `MetadataStore` collects all definitions -> after-suite hook or rake task merges them with component definitions -> writes OpenAPI 3.1 spec files.

```
Tests (DSL) + Components (Ruby classes)
        │                │
        ▼                ▼
   MetadataStore    Loader
        │                │
        └──────┬─────────┘
               ▼
        DocumentBuilder
               │
               ▼
         SpecWriter
               │
          ┌────┴────┐
          ▼         ▼
     spec.yaml   spec.json
```

**Rake task:** `rake openapi_rails:generate`
- Loads test files to populate MetadataStore (without executing tests)
- Merges with components
- Validates generated document against OA 3.1 meta-schema via `json_schemer`
- Writes output files

**After-suite hook:** Automatic generation after running tests (configurable).

### Workflow B: Validate against existing spec (committee-style)

An existing OpenAPI file is loaded by middleware or test helpers. Requests/responses are validated at runtime or in test assertions. No DSL needed — just the spec file and assertion helpers.

---

## 10. Swagger UI Integration (Optional)

Swagger UI is entirely optional. The gem serves OpenAPI spec files regardless; UI is an opt-in addition.

```ruby
# config/routes.rb
mount OpenapiRails::Engine => '/api-docs'
```

- Serves spec files at `/api-docs/public_api.yaml` (or .json) — always available
- Swagger UI at `/api-docs/ui` — only when `config.ui_enabled = true`
- Loads swagger-ui-dist from CDN by default (configurable to vendored assets or importmap)
- No hard dependency on swagger-ui-dist — users who don't enable UI pay no cost
- Supports `openapi_filter` proc to modify spec per-request (e.g., hide admin endpoints from public docs)
- Optional basic auth via configuration
- Custom UI template override via `app/views/openapi_rails/ui/index.html.erb`

---

## 11. Rails Generators

### `rails generate openapi_rails:install`
Creates:
- `config/initializers/openapi_rails.rb` (configuration)
- `spec/openapi_helper.rb` or `test/openapi_helper.rb` (test helper)
- `app/api_components/schemas/.keep`
- Adds engine mount to `config/routes.rb`

### `rails generate openapi_rails:component User schemas`
Creates:
- `app/api_components/schemas/user.rb` with boilerplate

---

## 12. Implementation Phases

### Phase 1: Foundation
- Gem skeleton (gemspec, Gemfile, Rakefile, .rubocop.yml, .github CI)
- `OpenapiRails` module, `Configuration`, `Errors`, `Version`
- `Core::Document`, `Core::DocumentBuilder` — in-memory OA 3.1 model
- `Components::Base`, `Components::Loader`, `Components::Registry`, `Components::KeyTransformer`
- `json_schemer` integration for schema validation
- Unit tests for core + components

### Phase 2: DSL + RSpec Adapter
- `DSL::Context`, `DSL::OperationContext`, `DSL::ResponseContext`, `DSL::MetadataStore`
- All DSL methods (parameter, request_body, response, schema, etc.)
- `Adapters::RSpec` — full integration (describe/it generation, let-based params, after-suite hook)
- `Testing::RequestBuilder`, `Testing::ResponseValidator`
- `Generator::SpecWriter`, JSON/YAML formatters
- Rake task `openapi_rails:generate`
- Integration tests with a dummy Rails app + RSpec

### Phase 3: Minitest Adapter
- `Adapters::Minitest` — full integration (module mixin, test_response helper, after_run hook)
- Integration tests with a dummy Rails app + Minitest

### Phase 4: Middleware
- `Middleware::RequestValidation`, `Middleware::ResponseValidation`
- `Middleware::Coercion`, `Middleware::ErrorHandler`, `Middleware::PathMatcher`
- `Middleware::SchemaResolver` (loads + caches OA doc)
- `Testing::Assertions` (assert_schema_conform, assert_request_schema_confirm, assert_response_schema_confirm)
- `Testing::Coverage`, `Testing::CoverageReporter`

### Phase 5: Rails Integration + Optional UI
- `Engine`, `Railtie` — middleware auto-insertion, component loading
- Specs controller (serves generated OA files)
- All generators (install, component)
- Route mounting
- Optional `UI::Engine` + UI controller (Swagger UI via CDN, vendorable)

### Phase 6: Polish
- Migration guide from rswag
- Performance: schema caching, lazy component loading
- README + API documentation
- CI matrix (Ruby 3.2+, Rails 7.0+/7.1+/7.2+/8.0+)
- Release v0.1.0

---

## 13. Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Single gem vs sub-gems | Single gem | No version skew, simpler install, optional requires keep it modular |
| Validation library | `json_schemer` ~> 2.4 | Only Ruby gem supporting JSON Schema 2020-12 + OA 3.1 natively |
| DSL architecture | Framework-agnostic core + thin adapters | Enables RSpec, Minitest, future frameworks without duplicating logic |
| Both workflows | Generate-from-tests AND validate-against-spec | Both are first-class; generated spec can feed the middleware |
| Component system | Ruby class inheritance + deep merge | Proven pattern, natural for Ruby, enables DRY schemas |
| Key transformation | camelCase by default | Matches JSON API conventions; configurable per-component |
| Swagger UI | Optional, CDN by default | Disabled by default; no hard dependency; vendorable for offline use |
| Path matching | Custom regexp-based | Simple, no extra dependency; OA templates map cleanly to regexps |
| Min Ruby | 3.2+ | Pattern matching, Data classes, modern syntax |
| Min Rails | 7.0+ | Current supported versions only |

---

## 14. Verification Plan

1. **Unit tests** — Core document model, component system, DSL parsing, key transformation, path matching
2. **Integration tests (RSpec)** — Dummy Rails app with full DSL specs, verify generated OA 3.1 files validate correctly
3. **Integration tests (Minitest)** — Same dummy app, Minitest integration, same spec generation
4. **Middleware tests** — Rack::Test exercising request/response validation, coercion, strict mode, error handling
5. **Component tests** — Inheritance, hidden components, scoped loading, key transformation, duplicate detection
6. **Generated spec validation** — Feed generated YAML/JSON through `json_schemer` OA 3.1 meta-schema validation
7. **Coverage tracking** — Verify coverage reports match actual test coverage of endpoints
8. **UI smoke test** — Mount engine, verify Swagger UI loads and renders spec
