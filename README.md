<p align="center">
  <img src="logo.svg" alt="openapi_ruby" width="200">
</p>

<h1 align="center">openapi_ruby</h1>

<p align="center">
  A unified OpenAPI toolkit for Rails that combines test-driven spec generation, reusable schema components as Ruby classes, and runtime request/response validation middleware. Supports OpenAPI 3.0 and 3.1. Works with both RSpec and Minitest.
</p>

Replaces [rswag](https://github.com/rswag/rswag), [rswag-schema-components](https://github.com/101skills-gmbh/rswag-schema-components), and [committee](https://github.com/interagent/committee) with a single gem.

## Key Features

- **OpenAPI 3.0 & 3.1** with JSON Schema 2020-12 (via [json_schemer](https://github.com/davishmcclurg/json_schemer))
- **Test-framework agnostic** — works with RSpec and Minitest
- **Schema components** as Ruby classes with inheritance
- **Runtime middleware** for request/response validation with deep type checking
- **Strong params** derived from schema components
- **Spec generation** from test definitions
- **Optional Swagger UI** via CDN

## Requirements

- Ruby >= 3.2
- Rails >= 7.0

## Installation

Add to your Gemfile:

```ruby
gem "openapi-ruby"
```

Run the install generator:

```bash
rails generate openapi_ruby:install
```

This creates:

- `config/initializers/openapi_ruby.rb` — configuration
- `spec/openapi_helper.rb` or `test/openapi_helper.rb` — test helper
- `app/api_components/` — directory for schema components
- `swagger/` — output directory for generated specs
- Engine mount in `config/routes.rb`

## Configuration

```ruby
# config/initializers/openapi_ruby.rb
OpenapiRuby.configure do |config|
  config.schemas = {
    public_api: {
      info: { title: "My API", version: "v1" },
      servers: [{ url: "/" }]
    }
  }

  config.component_paths = ["app/api_components"]
  config.camelize_keys = true
  config.schema_output_dir = "swagger"
  config.schema_output_format = :yaml

  # Runtime middleware (disabled by default)
  config.request_validation = :disabled   # :enabled, :disabled, :warn_only
  config.response_validation = :disabled

  # Test DSL: validate requests against declared operations before sending.
  # Enabled by default; set to false to disable.
  config.test_request_validation = true

  # Optional Swagger UI (disabled by default)
  config.ui_enabled = false
end
```

### OpenAPI Version

The default OpenAPI version is 3.1.0. To generate 3.0.x schemas (e.g., when using `nullable: true`):

```ruby
config.schemas = {
  public_api: {
    openapi_version: "3.0.3",
    info: { title: "My API", version: "v1" },
    servers: [{ url: "/" }]
  }
}
```

### Multiple Schemas with Scopes

For projects with multiple APIs, use `component_scope` to partition components:

```ruby
config.schemas = {
  "internal/v1/schema": {
    info: { title: "Internal API", version: "v1" },
    component_scope: :internal_v1
  },
  "public/v2/schema": {
    info: { title: "Public API", version: "v2" },
    component_scope: :public_v2
  }
}

# Infer scopes from directory structure (e.g., internal/v1/schemas/user.rb → :internal_v1)
config.component_scope_paths = {
  "internal/v1" => :internal_v1,
  "public/v2" => :public_v2
}
```

Components are automatically scoped based on their file path. Use `shared_component` to include a component in all schemas, or `component_scopes :scope1, :scope2` to assign explicitly.

## Schema Components

Define your API schemas as Ruby classes:

```ruby
# app/api_components/schemas/user.rb
class Schemas::User
  include OpenapiRuby::Components::Base

  schema(
    type: :object,
    required: %w[id name email],
    properties: {
      id: { type: :integer, readOnly: true },
      name: { type: :string },
      email: { type: :string },
      created_at: { type: [:string, :null], format: "date-time" }
    }
  )
end
```

### Inheritance

```ruby
class Schemas::AdminUser < Schemas::User
  schema(
    properties: {
      role: { type: :string, enum: %w[admin superadmin] }
    }
  )
end
```

Child schemas deep-merge with their parent — `AdminUser` has all of `User`'s properties plus `role`.

### Component Types

```ruby
class SecuritySchemes::BearerAuth
  include OpenapiRuby::Components::Base
  component_type :securitySchemes

  schema(
    type: :http,
    scheme: :bearer,
    bearerFormat: "JWT"
  )
end
```

Supported types: `schemas`, `parameters`, `securitySchemes`, `requestBodies`, `responses`, `headers`, `examples`, `links`, `callbacks`.

### Key Transformation

By default, snake_case keys are converted to camelCase in the output. Disable globally with `config.camelize_keys = false` or per-component:

```ruby
class Schemas::User
  include OpenapiRuby::Components::Base
  skip_key_transformation true
  # ...
end
```

### Scopes

Assign components to scopes for multiple API specs:

```ruby
class Schemas::AdminUser
  include OpenapiRuby::Components::Base
  component_scopes :admin
  # ...
end
```

### Class References

Instead of writing `$ref` strings manually, you can pass component classes directly anywhere a `$ref` is expected. This gives you typo protection (via `NameError`), IDE navigation, and less boilerplate:

```ruby
# Instead of:
schema "$ref" => "#/components/schemas/User"
schema type: :array, items: { "$ref" => "#/components/schemas/User" }

# You can write:
schema Schemas::User
schema type: :array, items: Schemas::User
```

This works in `schema`, `request_body`, and anywhere nested inside hash/array definitions. Non-component classes raise `ArgumentError`.

You can also use the explicit `.to_ref` method:

```ruby
Schemas::User.to_ref
# => { "$ref" => "#/components/schemas/User" }
```

Both class refs and string `$ref` hashes are fully supported — use whichever you prefer.

### Strong Params

Schema components can derive Rails strong params permit lists:

```ruby
Schemas::UserInput.permitted_params
# => [:name, :email]

# Handles nested objects and arrays:
# [:title, { tags: [] }, { address: [:street, :city] }]
```

Use the controller helper:

```ruby
class Api::V1::UsersController < ActionController::API
  include OpenapiRuby::ControllerHelpers

  def create
    user = User.new(openapi_permit(Schemas::UserInput))
    # ...
  end
end
```

Works with [ActionPolicy](https://github.com/palkan/action_policy) — use `permitted_params` inside your policy's `params_filter` block.

### Component Generator

```bash
rails generate openapi_ruby:component User schemas
rails generate openapi_ruby:component BearerAuth security_schemes
```

## Testing with RSpec

```ruby
# spec/openapi_helper.rb
require "openapi_ruby/rspec"
```

RSpec supports two DSL styles. Both generate the same OpenAPI spec and validate responses (and requests) against it.

### Style 1: `path` / `run_test!`

Schema definition and test execution are interleaved. Each `response` block uses `let` values and `run_test!` to send the request inline:

```ruby
# spec/requests/users_spec.rb
require "openapi_helper"

RSpec.describe "Users API", type: :openapi do
  path "/api/v1/users" do
    get "List users" do
      tags "Users"
      operationId "listUsers"
      produces "application/json"

      response 200, "returns all users" do
        schema type: :array, items: Schemas::User

        run_test! do
          expect(JSON.parse(response.body).length).to be > 0
        end
      end
    end

    post "Create a user" do
      tags "Users"
      consumes "application/json"

      request_body required: true, content: {
        "application/json" => { schema: Schemas::UserInput }
      }

      response 201, "user created" do
        schema Schemas::User
        let(:request_body) { { name: "Jane", email: "jane@example.com" } }
        run_test!
      end

      response 422, "validation errors" do
        schema Schemas::ValidationErrors
        let(:request_body) { { name: "" } }
        run_test!
      end
    end
  end

  path "/api/v1/users/{id}" do
    parameter name: :id, in: :path, schema: { type: :integer }, required: true

    get "Get a user" do
      response 200, "user found" do
        schema Schemas::User
        let(:id) { User.create!(name: "Jane", email: "jane@example.com").id }
        run_test!
      end

      response 404, "not found" do
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
```

### Style 2: `api_path` / `assert_api_response`

Schema definition at the top, normal RSpec examples underneath. Mirrors the Minitest DSL and is useful when you want basic schema validation separated from detailed edge-case tests:

```ruby
require "openapi_helper"

RSpec.describe "Users API", type: :openapi do
  openapi_schema :public_api

  api_path "/api/v1/users" do
    get "List users" do
      tags "Users"
      produces "application/json"

      response 200, "returns all users" do
        schema type: :array, items: Schemas::User
      end
    end

    post "Create a user" do
      consumes "application/json"

      request_body required: true, content: {
        "application/json" => { schema: Schemas::UserInput }
      }

      response 201, "user created" do
        schema Schemas::User
      end

      response 422, "validation errors" do
        schema Schemas::ValidationErrors
      end
    end
  end

  # Normal RSpec examples
  it "returns all users" do
    User.create!(name: "Jane", email: "jane@example.com")

    assert_api_response :get, 200 do
      expect(parsed_body.length).to eq(1)
    end
  end

  it "creates a user" do
    assert_api_response :post, 201, body: { name: "Jane", email: "jane@example.com" } do
      expect(parsed_body["name"]).to eq("Jane")
    end
  end
end
```

`assert_api_response` accepts `params:`, `headers:`, `body:`, and `path_params:` keyword arguments. It validates the response status and body schema automatically, then yields to the block for additional expectations.

### DSL Reference

| Method | Level | Description |
|--------|-------|-------------|
| `path(template, &block)` | Top | Define an API path (style 1) |
| `api_path(template, &block)` | Top | Define an API path (style 2) |
| `openapi_schema(name)` | Top | Set the schema name (style 2) |
| `get/post/put/patch/delete(summary, &block)` | Path | Define an operation |
| `tags(*tags)` | Operation | Tag the operation |
| `operationId(id)` | Operation | Set operation ID |
| `description(text)` | Operation | Operation description |
| `deprecated(bool)` | Operation | Mark as deprecated |
| `consumes(*types)` | Operation | Request content types |
| `produces(*types)` | Operation | Response content types |
| `security(schemes)` | Operation | Security requirements |
| `parameter(name:, in:, schema:, **opts)` | Path/Operation | Define a parameter |
| `request_body(required:, content:)` | Operation | Define request body |
| `response(status, description, &block)` | Operation | Define expected response |
| `schema(definition)` | Response | Response body schema |
| `header(name, schema:, **opts)` | Response | Response header |
| `run_test!(&block)` | Response | Execute request and validate (style 1) |
| `assert_api_response(method, status, **opts, &block)` | Example | Execute request and validate (style 2) |
| `parsed_body` | Example | Parsed JSON response body |

## Testing with Minitest

```ruby
# test/test_helper.rb
require "openapi_ruby/minitest"
```

```ruby
# test/integration/users_test.rb
require "test_helper"

class UsersApiTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :public_api

  api_path "/api/v1/users" do
    get "List users" do
      tags "Users"
      produces "application/json"

      response 200, "returns all users" do
        schema type: :array, items: Schemas::User
      end
    end

    post "Create a user" do
      consumes "application/json"

      request_body required: true, content: {
        "application/json" => { schema: Schemas::UserInput }
      }

      response 201, "user created" do
        schema Schemas::User
      end
    end
  end

  test "GET /api/v1/users returns users" do
    User.create!(name: "Jane", email: "jane@example.com")

    assert_api_response :get, 200 do
      assert_equal 1, parsed_body.length
    end
  end

  test "POST /api/v1/users creates a user" do
    assert_api_response :post, 201, body: { name: "Jane", email: "jane@example.com" } do
      assert_equal "Jane", parsed_body["name"]
    end
  end
end
```

## Spec Generation

Generate OpenAPI spec files without running tests:

```bash
rake openapi_ruby:generate
```

This loads spec/test files to collect API definitions and writes schemas without running any tests. It auto-detects the test framework, or you can set `FRAMEWORK=rspec` or `FRAMEWORK=minitest`. Custom patterns: `PATTERN="packs/*/spec/**/*_spec.rb"`.

Schemas are **only** written by the rake task — running tests (`bundle exec rspec`, `rails test`) does not generate or overwrite schema files. This prevents partial schema overwrites when running a subset of specs.

## Runtime Middleware

Validate requests and responses against your OpenAPI spec at runtime:

```ruby
OpenapiRuby.configure do |config|
  config.request_validation = :enabled    # :enabled, :disabled, :warn_only
  config.response_validation = :enabled
end
```

The middleware validates:

- **Requests**: parameter types, required parameters, request body schema (required fields, types, constraints like `minLength`), content types
- **Responses**: body schema with full `$ref` resolution, required fields, types

Invalid requests return `400` with details. Invalid responses return `500`. In `:warn_only` mode, validation errors are logged but requests pass through.

### Strict Mode

Strict mode can be enabled per-schema to return 404 for undocumented paths:

```ruby
config.schemas = {
  public_api: {
    info: { title: "My API", version: "v1" },
    strict_mode: true  # 404 for undocumented paths
  }
}
```

## Swagger UI

Enable optional Swagger UI:

```ruby
OpenapiRuby.configure do |config|
  config.ui_enabled = true
end
```

Visit `/api-docs/ui` to see your API documentation. Schema files are served at `/api-docs/schemas/:name`.

## Engine Routes

```ruby
# config/routes.rb
mount OpenapiRuby::Engine => "/api-docs"
```

## License

MIT
