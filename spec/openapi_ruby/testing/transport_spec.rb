# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::Testing::Transport do
  # Stands in for a Rails integration test / rspec-rails request example.
  let(:rails_context) do
    Class.new do
      attr_reader :calls, :response

      def initialize
        @calls = []
        @response = Struct.new(:status, :body).new(200, "{}")
      end

      def integration_session
        :session
      end

      def get(path, **kwargs)
        @calls << [:get, path, kwargs]
      end

      def post(path, **kwargs)
        @calls << [:post, path, kwargs]
      end
    end.new
  end

  # Stands in for a context including Rack::Test::Methods (Hanami, Sinatra, Rack).
  let(:rack_test_context) do
    Class.new do
      attr_reader :calls, :last_response

      def initialize
        @calls = []
        @last_response = Rack::MockResponse.new(200, {}, "{}")
      end

      def app
        :the_app_under_test
      end

      def get(path, params = {}, env = {})
        @calls << [:get, path, params, env]
      end

      def post(path, params = {}, env = {})
        @calls << [:post, path, params, env]
      end
    end.new
  end

  describe ".for" do
    it "picks the Rails transport for an integration session" do
      expect(described_class.for(rails_context)).to be_a(described_class::RailsIntegration)
    end

    it "picks the rack-test transport for a Rack::Test context" do
      expect(described_class.for(rack_test_context)).to be_a(described_class::RackTest)
    end

    # A suite can include Rack::Test::Methods alongside the Rails integration
    # helpers; the Rails session is the one that boots the app under test.
    it "prefers Rails when a context offers both APIs" do
      context = rails_context
      def context.last_response = nil

      expect(described_class.for(context)).to be_a(described_class::RailsIntegration)
    end

    # rack-test resolves `app` lazily, so without this the mistake surfaces as
    # a NameError raised from inside the gem.
    it "explains a rack-test context that never named its app" do
      context = rack_test_context
      context.singleton_class.undef_method(:app)

      expect { described_class.for(context) }
        .to raise_error(OpenapiRuby::Error, /needs the Rack app under test.*let\(:app\)/m)
    end

    context "with no request API at all" do
      # A hand-rolled harness defining only the verb methods. Rails suites have
      # shipped these, so they keep working rather than being second-guessed.
      it "falls back to the Rails transport on a Rails host" do
        expect(described_class.for(Object.new)).to be_a(described_class::RailsIntegration)
      end

      # Otherwise rack-test is simply missing, and dispatch would land on the
      # example-group DSL's own `get` — an error about `get` being unavailable
      # inside an example, which explains nothing.
      it "tells a non-Rails host how to wire rack-test" do
        allow(OpenapiRuby).to receive(:rails_host?).and_return(false)

        expect { described_class.for(Object.new) }
          .to raise_error(OpenapiRuby::Error, /Add rack-test.*include Rack::Test::Methods/m)
      end
    end
  end

  describe described_class::RailsIntegration do
    let(:context) { rails_context }
    let(:transport) { described_class.new(context) }

    it "dispatches params and headers as keywords" do
      transport.dispatch(:post, "/users", params: '{"name":"Ada"}', headers: {"Content-Type" => "application/json"})

      expect(context.calls).to eq([
        [:post, "/users", {params: '{"name":"Ada"}', headers: {"Content-Type" => "application/json"}}]
      ])
    end

    it "omits keywords that were not supplied" do
      transport.dispatch(:get, "/users", headers: {"Accept" => "application/json"})

      expect(context.calls).to eq([[:get, "/users", {headers: {"Accept" => "application/json"}}]])
    end

    it "exposes the Rails response" do
      expect(transport.response.status).to eq(200)
    end
  end

  describe described_class::RackTest do
    let(:context) { rack_test_context }
    let(:transport) { described_class.new(context) }

    it "dispatches params positionally and headers as a Rack env" do
      transport.dispatch(:post, "/users", params: '{"name":"Ada"}', headers: {"Content-Type" => "application/json"})

      expect(context.calls).to eq([
        [:post, "/users", '{"name":"Ada"}', {"CONTENT_TYPE" => "application/json"}]
      ])
    end

    it "prefixes non-entity headers with HTTP_ and underscores them" do
      transport.dispatch(:get, "/users", headers: {"Accept" => "application/json", "X-Api-Key" => "secret"})

      expect(context.calls.first.last).to eq(
        "HTTP_ACCEPT" => "application/json",
        "HTTP_X_API_KEY" => "secret"
      )
    end

    it "keeps Content-Length out of the HTTP_ namespace" do
      transport.dispatch(:post, "/users", params: "abc", headers: {"Content-Length" => 3})

      expect(context.calls.first.last).to eq("CONTENT_LENGTH" => "3")
    end

    it "sends an empty params hash when none were supplied" do
      transport.dispatch(:get, "/users", headers: {})

      expect(context.calls).to eq([[:get, "/users", {}, {}]])
    end

    it "exposes the rack-test response" do
      expect(transport.response.status).to eq(200)
    end
  end
end
