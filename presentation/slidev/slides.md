---
theme: none
title: openapi_ruby
info: OpenAPI docs, tests & runtime validation from one source — in Rails.
class: lcars
highlighter: shiki
lineNumbers: false
fonts:
  sans: Barlow
  mono: JetBrains Mono
  # Antonio used for headings via CSS below
drawings:
  persist: false
transition: fade
mdc: true
---

<style>
/* ------- LCARS theme -------
   Load fonts (Slidev fetches `fonts:` above; Antonio added here) */
@import url('https://fonts.googleapis.com/css2?family=Antonio:wght@400;600;700&family=Barlow:wght@400;500;600&family=JetBrains+Mono:wght@400;500;700&display=swap');

:root {
  --bg:#0a0e17; --gold:#e9a94d; --coral:#e4594c; --teal:#3bb5ae;
  --cream:#ead9b0; --steel:#5e8fc0; --body:#ede6d6; --panel:#0d131e;
}

.slidev-layout {
  background:
    radial-gradient(ellipse 1000px 680px at 60% 46%, rgba(233,169,77,0.13), rgba(228,89,76,0.05) 42%, transparent 72%),
    linear-gradient(rgba(94,143,192,0.045) 1px, transparent 1px),
    linear-gradient(90deg, rgba(94,143,192,0.045) 1px, transparent 1px),
    var(--bg);
  background-size: auto, 100% 72px, 72px 100%, auto;
  color: var(--body);
  font-family: 'Barlow', sans-serif;
  padding: 150px 56px 80px 176px;
  position: relative;
}

/* --- persistent LCARS frame (drawn per slide via ::before/::after + rails) --- */
.lcars-frame { position:absolute; inset:0; pointer-events:none; z-index:0; }
.lcars-frame .elbow { position:absolute; left:24px; top:24px; width:300px; height:104px; background:var(--gold); border-radius:80px 0 0 0; }
.lcars-frame .rail  { position:absolute; left:24px; top:136px; bottom:64px; width:120px; display:flex; flex-direction:column; gap:8px; }
.lcars-frame .rail > i { display:block; }
.lcars-frame .rail > i:nth-child(1){ flex:2.4; background:var(--gold); }
.lcars-frame .rail > i:nth-child(2){ flex:1.1; background:var(--coral); }
.lcars-frame .rail > i:nth-child(3){ flex:1.7; background:var(--teal); }
.lcars-frame .rail > i:nth-child(4){ flex:0.8; background:var(--cream); }
.lcars-frame .rail > i:nth-child(5){ flex:2.0; background:var(--steel); }
.lcars-frame .rail > i:nth-child(6){ flex:0.9; background:var(--gold); }
.lcars-frame .rail > i:nth-child(7){ flex:1.3; background:var(--coral); border-radius:0 0 0 60px; }
.lcars-frame .topbar { position:absolute; left:332px; right:24px; top:24px; height:56px; display:flex; gap:8px; }
.lcars-frame .topbar .tag { background:var(--gold); color:var(--bg); font-family:'Antonio',sans-serif; font-weight:700; font-size:26px; letter-spacing:4px; display:flex; align-items:center; padding:0 26px; border-radius:0 28px 28px 0; }
.lcars-frame .topbar .s1 { width:40px; background:var(--teal); border-radius:6px; }
.lcars-frame .topbar .fill { flex:1; background:#141b28; border-radius:6px; }
.lcars-frame .topbar .s2 { width:26px; background:var(--coral); border-radius:6px; }
.lcars-frame .topbar .readout { min-width:280px; background:#141b28; border-radius:6px 28px 28px 6px; display:flex; align-items:center; justify-content:flex-end; padding:0 28px; color:var(--gold); font-family:'JetBrains Mono',monospace; font-size:19px; letter-spacing:2px; }
.lcars-frame .botbar { position:absolute; left:152px; right:24px; bottom:24px; height:26px; display:flex; gap:8px; }
.lcars-frame .botbar .b1 { width:60px; background:var(--steel); border-radius:6px 0 0 6px; }
.lcars-frame .botbar .lab { background:#141b28; border-radius:6px; display:flex; align-items:center; padding:0 20px; color:var(--steel); font-family:'JetBrains Mono',monospace; font-size:14px; letter-spacing:3px; }
.lcars-frame .botbar .fill { flex:1; background:#141b28; border-radius:6px; }
.lcars-frame .botbar .b2 { width:120px; background:var(--gold); border-radius:6px; }
.lcars-frame .botbar .b3 { width:34px; background:var(--teal); border-radius:0 6px 6px 0; }

/* content sits above frame */
.lcars-frame ~ * { position:relative; z-index:1; }

/* typography helpers */
.eyebrow { font-family:'JetBrains Mono',monospace; font-size:24px; letter-spacing:5px; text-transform:uppercase; color:var(--coral); margin-bottom:20px; }
h1.lc { font-family:'Antonio',sans-serif; font-weight:700; text-transform:uppercase; letter-spacing:2px; color:var(--gold); line-height:0.98; margin:0; }
.title { font-size:72px; }
.h2 { font-size:88px; }
.sub { font-size:40px; color:var(--body); }
.cap { font-size:30px; }
.small { font-size:24px; }
.teal{color:var(--teal);} .coral{color:var(--coral);} .cream{color:var(--cream);} .steel{color:var(--steel);} .gold{color:var(--gold);}

/* code panels: coral left rail, dark bg */
.slidev-layout pre, .slidev-layout .shiki {
  background: var(--panel) !important;
  border:1px solid rgba(94,143,192,0.16);
  border-left:5px solid var(--coral);
  border-radius:10px; padding:28px 32px !important;
  font-size:26px; line-height:1.6;
}
.card { background:var(--panel); border:1px solid rgba(94,143,192,0.18); border-radius:12px; padding:30px 34px; }
.card.here { background:#140f0a; border-color:var(--gold); }
</style>

<!-- Reusable LCARS frame. Slidev renders raw HTML in markdown. The readout number
     is hand-set per slide (Slidev has no built-in "current/total" var in-markdown;
     if you want it live, wire $slidev.nav.currentPage / .total in a Vue component). -->

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 01/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div class="eyebrow">Ruby Usergroup // Engineering Briefing</div>
<div style="font-family:'JetBrains Mono',monospace;font-weight:700;font-size:140px;line-height:0.92;color:var(--cream);letter-spacing:-2px;">openapi_ruby</div>
<div class="sub" style="margin-top:34px;max-width:1150px;line-height:1.3;">OpenAPI docs, tests &amp; runtime validation from one source — in Rails.</div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;margin-top:44px;">v4.0.1 · MIT · Ruby ≥ 3.2 · Rails ≥ 7</div>

<!--
Hook. Quick show of hands — who here has an API where the docs and the real API have quietly drifted apart? Yeah. That's the whole talk. This is openapi_ruby: one source of truth for your docs, your tests, and runtime validation, built for Rails.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 02/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div class="eyebrow">Personnel // Speaker</div>
<h1 class="lc h2">Marten Klitzke</h1>
<div class="sub" style="margin-top:18px;">Software Engineer · fobizz</div>
<div style="display:flex;gap:60px;margin-top:56px;font-family:'JetBrains Mono',monospace;font-size:24px;">
  <div><span class="steel">web&nbsp;&nbsp;&nbsp;&nbsp;</span> <a href="https://marten.klitzke.xyz" style="color:var(--teal);">marten.klitzke.xyz</a></div>
  <div><span class="steel">github&nbsp;</span> <a href="https://github.com/mortik" style="color:var(--teal);">@mortik</a></div>
</div>

<!--
Quick intro. I'm Marten, software engineer at fobizz — we're an edtech company, a Rails shop with a real public-ish API surface. So this gem isn't a hobby thing, it's the tool I reach for at the day job.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 03/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div class="eyebrow">Diagnostic // contract drift</div>
<h1 class="lc title">One contract, written three times</h1>

<div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:26px;margin-top:40px;">
<div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;text-transform:uppercase;margin-bottom:10px;">app/serializers/order.rb</div>

```ruby
json.id       order.id
json.status   order.state
# json.email removed last week
```

<div class="small" style="margin-top:10px;">no longer sends <span class="coral">email</span></div>
</div>
<div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;text-transform:uppercase;margin-bottom:10px;">openapi.yaml</div>

```yaml
Order:
  required:
    - id
    - status
    - email
```

<div class="small" style="margin-top:10px;">still lists <span class="coral">email</span> as required</div>
</div>
<div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;text-transform:uppercase;margin-bottom:10px;">order_spec.rb</div>

```ruby
get order_path(order)
expect(response)
  .to have_http_status(:ok)
```

<div class="small" style="margin-top:10px;">never looks at the body</div>
</div>
</div>

<div class="cap cream" style="margin-top:28px;">All three are green. The docs still promise a field the API stopped sending.</div>

<!--
Here's the drift. Someone dropped the email field from the serializer last week — reasonable, maybe a privacy thing. But the OpenAPI doc is a separate hand-maintained file, and it still lists email as required. And the request spec only checks that the response is a 200 — it never looks at the body. So all three are green: code ships, CI passes, docs look fine. Meanwhile every client that trusted the documented contract and expected a required email is now breaking in production. Nothing here forced these three to agree — that's the whole problem, and it's exactly what one shared definition fixes.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 04/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div style="display:flex;align-items:center;gap:70px;height:100%;">
<div style="flex:1;">
<div class="eyebrow">Primer // 101</div>
<h1 class="lc h2">Your API —<br>as a document.</h1>
<div class="cap" style="margin-top:30px;max-width:520px;line-height:1.35;">Machine-readable. Formerly Swagger. Watch the <span class="teal" style="font-family:'JetBrains Mono',monospace;">$ref</span> strings.</div>
</div>
<div style="flex:1.05;">

```yaml
paths:
  /users/{id}:
    get:
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
```

</div>
</div>

<!--
Quick 101 for anyone who hasn't met it. OpenAPI is just your API written down as a document a machine can read — it used to be called Swagger. Paths, methods, responses, and the shapes of the data. Keep your eye on those $ref strings — those little pointers into a components section are where everything ties together, and they matter later.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 05/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div class="eyebrow">Survey // the landscape</div>
<h1 class="lc title">OpenAPI on Rails: pick your poison</h1>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:26px;margin-top:40px;">
  <div class="card"><div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;">01</div><div style="font-family:'Antonio',sans-serif;font-weight:600;text-transform:uppercase;letter-spacing:1px;font-size:40px;color:var(--cream);margin:8px 0;">Hand-write the YAML</div><div class="small">You and a 3000-line file.</div></div>
  <div class="card"><div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;">02</div><div style="font-family:'Antonio',sans-serif;font-weight:600;text-transform:uppercase;letter-spacing:1px;font-size:40px;color:var(--cream);margin:8px 0;">Annotate controllers</div><div class="small">apipie — docs in comments.</div></div>
  <div class="card"><div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;">03</div><div style="font-family:'Antonio',sans-serif;font-weight:600;text-transform:uppercase;letter-spacing:1px;font-size:40px;color:var(--cream);margin:8px 0;">Grape + grape-swagger</div><div class="small">A whole different framework.</div></div>
  <div class="card here"><div class="small gold" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;">04 · you are here</div><div style="font-family:'Antonio',sans-serif;font-weight:600;text-transform:uppercase;letter-spacing:1px;font-size:40px;color:var(--gold);margin:8px 0;">Generate from tests</div><div class="small">rswag + committee.</div></div>
</div>

<!--
There's no single status quo on Rails — you've got a few options, all with tradeoffs. Hand-write the YAML and babysit a 3000-line file. Annotate your controllers with apipie. Switch frameworks to Grape and use grape-swagger. Or generate the spec from your tests with rswag plus committee. openapi_ruby lives in that last camp. Honest aside: rswag is still 3.0-only — the 3.1 issue has been open since 2021 — and it's currently seeking maintainers. That gap is part of why this exists.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 06/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div style="font-family:'JetBrains Mono',monospace;font-weight:700;font-size:110px;line-height:0.92;color:var(--cream);letter-spacing:-2px;">openapi_ruby</div>
<div class="cap steel" style="margin-top:20px;">One gem. Three jobs. One definition.</div>
<div style="display:flex;gap:26px;margin-top:48px;">
  <div class="card" style="flex:1;border-top:4px solid var(--gold);"><div style="font-family:'JetBrains Mono',monospace;font-size:40px;color:var(--gold);">01</div><div style="font-family:'Antonio',sans-serif;font-weight:700;text-transform:uppercase;letter-spacing:2px;font-size:40px;color:var(--cream);margin-top:8px;">Components</div><div class="small" style="margin-top:10px;">Schemas as Ruby classes.</div></div>
  <div class="card" style="flex:1;border-top:4px solid var(--teal);"><div style="font-family:'JetBrains Mono',monospace;font-size:40px;color:var(--teal);">02</div><div style="font-family:'Antonio',sans-serif;font-weight:700;text-transform:uppercase;letter-spacing:2px;font-size:40px;color:var(--cream);margin-top:8px;">Generation</div><div class="small" style="margin-top:10px;">Spec from tests.</div></div>
  <div class="card" style="flex:1;border-top:4px solid var(--coral);"><div style="font-family:'JetBrains Mono',monospace;font-size:40px;color:var(--coral);">03</div><div style="font-family:'Antonio',sans-serif;font-weight:700;text-transform:uppercase;letter-spacing:2px;font-size:40px;color:var(--cream);margin-top:8px;">Validation</div><div class="small" style="margin-top:10px;">Runtime middleware.</div></div>
</div>

<!--
So — openapi_ruby. One gem, three jobs. Components: your schemas as Ruby classes. Generation: the spec comes out of your tests. Validation: runtime middleware that checks requests and responses. And the whole point is they all read one definition, through one engine — json_schemer under the hood.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 07/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div style="display:flex;align-items:center;gap:70px;height:100%;">
<div style="flex:0.85;">
<div class="eyebrow">Subsystem 01 // components</div>
<h1 class="lc h2">Schemas as<br>Ruby classes</h1>
<div class="cap" style="margin-top:28px;max-width:440px;line-height:1.35;">Autoloaded. camelCased output. Every component type.</div>
</div>
<div style="flex:1.15;">

```ruby
class Schemas::User
  include OpenapiRuby::Components::Base

  schema type: :object do
    property :id,        :integer
    property :full_name, :string
    property :email,     :string, format: :email
    required :id, :full_name
  end
end
```

</div>
</div>

<!--
Subsystem one: components. A schema is just a Ruby class that includes the base module and declares a schema block. It's autoloaded like anything else in the app, the output gets camelCased to match JSON conventions, and it covers all the OpenAPI component types — not just object schemas.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 08/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div class="eyebrow">Subsystem 01 // composition</div>
<h1 class="lc title">Because they're classes, they compose</h1>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:30px;margin-top:36px;">
<div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px;">Inheritance → deep-merge</div>

```ruby
class Schemas::AdminUser < Schemas::User
  schema do
    property :role, :string
  end
end
```

</div>
<div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px;">Class refs → no magic strings</div>

```ruby
# instead of a magic string:
"$ref" => "#/components/schemas/User"

# reference the class:
schema Schemas::User
```

</div>
</div>

<!--
And because they're just classes, they compose the way Ruby already does. Inheritance deep-merges the parent schema, so AdminUser is a User plus a role. And instead of hand-typing a $ref string, you reference the class directly. Typo the class and you get a NameError at boot, not a broken doc in production — plus jump-to-definition just works.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 09/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div style="display:flex;align-items:center;gap:70px;height:100%;">
<div style="flex:0.8;">
<div class="eyebrow">Subsystem 02 // generation</div>
<h1 class="lc h2">The spec comes from your tests</h1>
<div class="cap" style="margin-top:28px;max-width:420px;line-height:1.35;">One block is <span class="teal">both</span> the doc source and the test.</div>
</div>
<div style="flex:1.2;">

```ruby
path '/users/{id}' do
  get 'fetch a user' do
    response 200, 'ok' do
      schema Schemas::User
      run_test!
    end
  end
end
```

</div>
</div>

<!--
Subsystem two: generation. This block is the heart of it. It reads like an RSpec example — path, get, response, done. But it's doing double duty: it's both the source for the doc AND a real test. run_test! fires an actual request against your app and checks the response matches the schema. If it passes, the spec it produces is verified, not just asserted.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 10/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div class="eyebrow">RSpec: either · Minitest: style 2 · same output</div>
<h1 class="lc title">Two ways to write it</h1>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:30px;margin-top:32px;">
<div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px;">Style 1 — interleaved</div>

```ruby
path '/users/{id}' do
  get 'fetch a user' do
    response 200, 'ok' do
      schema Schemas::User
      run_test!
    end
  end
end
```

</div>
<div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px;">Style 2 — schema up top</div>

```ruby
api_path '/users/{id}' do
  get 'fetch a user' do
    response 200, schema: Schemas::User
  end
end

test "fetches a user" do
  get user_path(user)
  assert_api_response 200
end
```

</div>
</div>

<!--
There are two ways to write the same thing. Style one interleaves the request into the block, run_test! and all — very RSpec. Style two declares the schema up top with api_path, then a plain separate test asserts the response. Style two is the Minitest DSL — it's first-class here, not bolted on. RSpec folks can use either; Minitest folks use style two. Same spec out the other end.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 11/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div class="eyebrow">Subsystem 02 // output</div>
<h1 class="lc title">Test in, spec out</h1>

<div style="display:grid;grid-template-columns:1fr 44px 1fr;gap:18px;margin-top:36px;align-items:center;">
<div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px;">The test you wrote · Ruby</div>

```ruby
response 200, 'ok' do
  schema Schemas::User
  run_test!
end
```

</div>
<div style="font-family:'Antonio',sans-serif;font-size:52px;color:var(--gold);text-align:center;">→</div>
<div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px;">Generated · OpenAPI YAML</div>

```yaml
'200':
  content:
    application/json:
      schema:
        $ref: '#/components/schemas/User'
```

</div>
</div>

<div class="cap cream" style="margin-top:26px;">Produced by <span class="teal" style="font-family:'JetBrains Mono',monospace;">rake openapi_ruby:generate</span> — an explicit step, never a side effect of tests.</div>

<!--
Here's the payoff of subsystem two, side by side. On the left, the test you actually wrote. On the right, the OpenAPI it generates — and notice Schemas::User resolved itself into a clean $ref. Zero YAML written by hand. And because that test passed, the doc isn't just generated, it's verified against a real response. This is an explicit rake step, by the way — never a silent side effect of running your suite.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 12/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div style="display:flex;align-items:center;gap:70px;height:100%;">
<div style="flex:0.85;">
<div class="eyebrow">Subsystem 03 // validation</div>
<h1 class="lc h2">Validation at runtime</h1>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;margin-top:26px;line-height:1.7;">:enabled&nbsp;&nbsp;|&nbsp;&nbsp;:disabled&nbsp;&nbsp;|&nbsp;&nbsp;:warn_only</div>
<div class="cap cream" style="margin-top:24px;line-height:1.4;">bad request → <span class="coral">400</span><br>bad response → <span class="coral">500</span></div>
</div>
<div style="flex:1.15;">

```ruby
OpenapiRuby.configure do |config|
  config.request_validation  = :enabled
  config.response_validation = :warn_only
end
```

</div>
</div>

<!--
Subsystem three: validation at runtime. Same definition, now enforced in the live app as Rack middleware. You flip request and response validation independently — enabled, disabled, or warn_only. A bad request gets a 400; a bad response gets a 500, because a wrong response is your bug, not the client's. It's off by default — the sane rollout is warn_only first, watch the logs, then turn it on.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 13/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div class="eyebrow">Subsystem 03 // freebies</div>
<h1 class="lc title">Also derived from the same components</h1>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:30px;margin-top:36px;">
<div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px;">Strong params from the schema</div>

```ruby
def user_params
  openapi_permit(Schemas::UserInput)
end
```

</div>
<div>
<div class="small steel" style="font-family:'JetBrains Mono',monospace;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px;">Swagger UI, opt-in</div>

```ruby
# config/routes.rb
mount OpenapiRuby::Engine => '/api-docs'

# config/initializers
config.ui_enabled = true
```

</div>
</div>

<!--
Two nice freebies fall out of having one contract. Strong params: openapi_permit builds your permit list straight from the input schema, so params and docs can't disagree. And a Swagger UI: mount the engine, flip ui_enabled, and you've got live docs — opt-in, off by default. You define the contract once and keep getting things for free.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 14/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div class="eyebrow">Diagnosis // resolved</div>
<div style="display:flex;flex-direction:column;gap:30px;margin-top:20px;">
  <div style="font-family:'Antonio',sans-serif;font-weight:700;text-transform:uppercase;letter-spacing:2px;font-size:82px;color:var(--gold);line-height:1;">Define it once.</div>
  <div style="font-family:'Antonio',sans-serif;font-weight:700;text-transform:uppercase;letter-spacing:2px;font-size:82px;color:var(--gold);line-height:1;">Same checks in tests and prod.</div>
  <div style="font-family:'Antonio',sans-serif;font-weight:700;text-transform:uppercase;letter-spacing:2px;font-size:82px;color:var(--gold);line-height:1;">Docs are your passing tests.</div>
</div>
<div class="cap steel" style="margin-top:48px;">Three views of one definition — one engine underneath.</div>

<!--
So here's the whole payoff in three lines. Define it once. Run the same checks in tests and in production. And your docs are literally your passing tests. Docs, tests, and validation stop being three things you keep in sync by hand — they're three views of one definition, all reading it through the same engine. That's why it can't drift.
-->

---

<div class="lcars-frame">
  <div class="elbow"></div>
  <div class="rail"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>
  <div class="topbar"><div class="tag">OPENAPI-RUBY</div><div class="s1"></div><div class="fill"></div><div class="s2"></div><div class="readout">NCC · SEC 15/15</div></div>
  <div class="botbar"><div class="b1"></div><div class="lab">ENGINEERING</div><div class="fill"></div><div class="b2"></div><div class="b3"></div></div>
</div>

<div style="display:flex;flex-direction:column;justify-content:center;height:100%;">
<div style="font-family:'Antonio',sans-serif;font-weight:700;text-transform:uppercase;letter-spacing:3px;font-size:180px;color:var(--cream);line-height:0.9;">Thank you</div>
<div style="font-family:'Antonio',sans-serif;font-weight:600;text-transform:uppercase;letter-spacing:4px;font-size:88px;color:var(--teal);margin-top:24px;">Questions?</div>
</div>

<!--
That's openapi_ruby. Thank you — happy to take questions.
-->
