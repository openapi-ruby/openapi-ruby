# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRails::Error do
  it "inherits from StandardError" do
    expect(described_class).to be < StandardError
  end
end

RSpec.describe OpenapiRails::InvalidDocumentError do
  it "includes validation errors in the message" do
    errors = [{ "error" => "missing title" }, { "error" => "bad version" }]
    error = described_class.new(errors)

    expect(error.message).to include("missing title")
    expect(error.message).to include("bad version")
    expect(error.validation_errors).to eq(errors)
  end
end

RSpec.describe OpenapiRails::DuplicateComponentError do
  it "inherits from Error" do
    expect(described_class).to be < OpenapiRails::Error
  end
end
