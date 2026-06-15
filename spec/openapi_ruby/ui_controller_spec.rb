# frozen_string_literal: true

require "spec_helper"
require_relative "../support/rails_app"
require "openapi_ruby/engine"
require "openapi_ruby/ui_controller"

# Direct unit tests of the UiController's HTML rendering. The engine route is
# conditional on `ui_enabled`, so going through full routing would force a
# route reload; tests here exercise the rendering helpers directly.
RSpec.describe OpenapiRuby::UiController do
  let(:controller) { described_class.new }
  let(:url_helpers) { OpenapiRuby::Engine.routes.url_helpers }

  before do
    OpenapiRuby.configuration.schemas = {default: {info: {title: "API"}}}
    OpenapiRuby.configuration.schema_output_format = :yaml
    allow(url_helpers).to receive(:schema_path).and_return("/api-docs/schemas/default.yaml")
    allow(controller).to receive(:openapi_ruby).and_return(url_helpers)
  end

  def render_html(ui_config: {}, oauth_config: nil)
    OpenapiRuby.configuration.ui_config = ui_config
    OpenapiRuby.configuration.oauth_config = oauth_config
    controller.instance_variable_set(:@schemas, OpenapiRuby.configuration.schemas)
    controller.instance_variable_set(:@ui_config, ui_config)
    controller.instance_variable_set(:@oauth_config, controller.send(:resolve_oauth_config, oauth_config))
    controller.send(:swagger_ui_html)
  end

  describe "oauth_config" do
    it "omits ui.initOAuth when oauth_config is nil" do
      expect(render_html).not_to include("initOAuth")
    end

    it "omits ui.initOAuth when oauth_config is an empty hash" do
      expect(render_html(oauth_config: {})).not_to include("initOAuth")
    end

    it "omits ui.initOAuth when a callable returns nil" do
      nil_callable = ->(_ctrl) {}
      expect(render_html(oauth_config: nil_callable)).not_to include("initOAuth")
    end

    it "renders ui.initOAuth with a hash oauth_config" do
      html = render_html(oauth_config: {clientId: "abc", appName: "My API"})
      expect(html).to include('ui.initOAuth({"clientId":"abc","appName":"My API"});')
    end

    it "renders ui.initOAuth with a callable returning a hash" do
      html = render_html(oauth_config: ->(_ctrl) { {clientId: "xyz"} })
      expect(html).to include('ui.initOAuth({"clientId":"xyz"});')
    end

    it "passes the controller instance to the callable" do
      received = nil
      render_html(oauth_config: ->(ctrl) { {}.tap { received = ctrl } })
      expect(received).to be(controller)
    end

    it "does not pass </script> through unescaped in oauth_config values" do
      html = render_html(oauth_config: {clientId: "</script><script>alert(1)</script>"})
      expect(html).not_to include("</script><script>alert(1)</script>")
    end

    it "escapes </script> as <\\/script> in oauth_config values" do
      html = render_html(oauth_config: {clientId: "</script><script>alert(1)</script>"})
      expect(html).to include('<\/script><script>alert(1)<\/script>')
    end
  end

  describe "ui_config" do
    it "does not pass </script> through unescaped in ui_config values" do
      html = render_html(ui_config: {someKey: "</script><script>alert(1)</script>"})
      expect(html).not_to include("</script><script>alert(1)</script>")
    end

    it "escapes </script> as <\\/script> in ui_config values" do
      html = render_html(ui_config: {someKey: "</script><script>alert(1)</script>"})
      expect(html).to include('<\/script><script>alert(1)<\/script>')
    end
  end

  describe "schema URLs" do
    it "escapes </script> in generated schema URLs" do
      allow(url_helpers).to receive(:schema_path).and_return("/schemas/</script><script>x</script>")
      html = render_html
      expect(html).not_to include("</script><script>x</script>")
    end
  end
end
