# frozen_string_literal: true

require "spec_helper"
require "openapi_ruby/sorbet"

RSpec.describe OpenapiRuby::Components::TypedParams do
  before { OpenapiRuby::Components::Registry.instance.clear! }

  def create_struct(name, &block)
    klass = Class.new(T::Struct)
    stub_const(name, klass)
    klass.include(OpenapiRuby::Components::Base)
    klass.include(described_class)
    klass.class_eval(&block) if block
    klass
  end

  let!(:user_input) do
    create_struct("UserInput") do
      schema(
        type: :object,
        required: %w[name email],
        properties: {
          name: {type: :string},
          email: {type: :string},
          bio: {type: :string, nullable: true},
          age: {type: :integer},
          score: {type: :number},
          active: {type: :boolean},
          tags: {type: :array, items: {type: :string}},
          meta: {type: :object}
        }
      )
    end
  end

  it "builds an immutable struct from the schema" do
    user = user_input.new(name: "Jane", email: "jane@example.com")

    expect(user.name).to eq("Jane")
    expect(user.bio).to be_nil
    expect(user).not_to respond_to(:name=)
  end

  it "maps OpenAPI types to Sorbet types" do
    types = user_input.props.transform_values { |r| r[:type_object].to_s }

    expect(types).to include(
      name: "String",
      email: "String",
      bio: "T.nilable(String)",
      age: "T.nilable(Integer)",
      score: "T.nilable(T.any(Integer, Float))",
      active: "T.nilable(T::Boolean)",
      tags: "T.nilable(T::Array[String])",
      meta: "T.nilable(T::Hash[String, T.untyped])"
    )
  end

  it "requires required properties" do
    expect { user_input.new(name: "Jane") }.to raise_error(ArgumentError)
  end

  it "keeps schema output and permitted_params unchanged" do
    expect(user_input.permitted_params).to include(:name, :email, :bio)
    expect(user_input.to_openapi["required"]).to eq(%w[name email])
  end

  it "resolves $ref and arrays of $ref to component classes" do
    address = create_struct("Address") do
      schema(type: :object, required: %w[city], properties: {city: {type: :string}})
    end
    order = create_struct("Order") do
      schema(
        type: :object,
        required: %w[address],
        properties: {
          address: {"$ref" => "#/components/schemas/Address"},
          history: {type: :array, items: address}
        }
      )
    end

    result = order.new(address: address.new(city: "Oslo"), history: [address.new(city: "Rome")])
    expect(result.address.city).to eq("Oslo")
    expect(result.history.first.city).to eq("Rome")
  end

  it "raises for refs that cannot be resolved" do
    expect {
      create_struct("Broken") do
        schema(type: :object, properties: {x: {"$ref" => "#/components/schemas/Missing"}})
      end
    }.to raise_error(ArgumentError, /Missing/)
  end

  it "accepts integers for number properties" do
    expect(user_input.new(name: "A", email: "a@b.c", score: 1).score).to eq(1)
  end

  it "maps type unions to T.any" do
    klass = create_struct("Union") do
      schema(type: :object, properties: {v: {type: [:string, :integer, :null]}})
    end

    expect(klass.props[:v][:type_object].to_s).to eq("T.nilable(T.any(String, Integer))")
  end

  it "requires required nullable properties to be passed" do
    klass = create_struct("Nullable") do
      schema(type: :object, required: %w[note], properties: {note: {type: :string, nullable: true}})
    end

    expect { klass.new }.to raise_error(ArgumentError, /note/)
    expect(klass.new(note: nil).note).to be_nil
  end

  it "rejects later schema calls that change a declared prop" do
    klass = create_struct("Evolving") do
      schema(type: :object, properties: {name: {type: :string}})
    end

    expect { klass.schema(required: %w[name]) }.to raise_error(ArgumentError, /name/)
  end

  it "does not resolve refs to a class of another component type or scope" do
    other = Class.new
    stub_const("Other::Address", other)
    other.include(OpenapiRuby::Components::Base)
    other.component_type(:parameters)

    expect {
      create_struct("NeedsAddress") do
        schema(type: :object, properties: {a: {"$ref" => "#/components/schemas/Address"}})
      end
    }.to raise_error(ArgumentError, /Address/)
  end

  it "requires a T::Struct that includes Base" do
    plain = Class.new
    expect { plain.include(described_class) }.to raise_error(ArgumentError, /T::Struct/)

    struct = Class.new(T::Struct)
    expect { struct.include(described_class) }.to raise_error(ArgumentError, /Base/)
  end
end
