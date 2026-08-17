# Design prompt — openapi_ruby talk

Paste everything below into Claude (or another design/slide tool) to regenerate
or redesign this presentation. It is self-contained.

---

You are designing a **conference-style slide deck** for a Ruby usergroup talk
introducing the gem **openapi_ruby** (an OpenAPI 3.0/3.1 toolkit for Rails:
test-driven spec generation, schema components as Ruby classes, and runtime
request/response validation middleware).

## Audience & tone
- Mixed Ruby developers — some know OpenAPI, some don't (include a brief 101).
- Speaker voice is **casual and human** — like a real dev at a meetup, not a
  vendor. Contractions, dry humor, honest about tradeoffs. Never salesy.

## Presentation style — "hybrid minimal"
- **One idea or one code block per slide.** No explanatory paragraphs or bullet
  lists on the slide itself.
- All the explanation lives in **speaker notes** (a short spoken paragraph per
  slide), not on screen.
- **Code stays** — it's the visual for a technical talk. Everything else is
  trimmed to a headline plus at most one short caption line.
- ~14 content slides + a closing slide. Target 13–18 min.

## Visual theme — Star Trek: Strange New Worlds / LCARS console
Warm brass-and-teal LCARS on a deep navy-black. Not pure black, not the cold
classic-LCARS purple.

Palette (CSS custom properties):
- background  `#0a0e17`  (deep navy-black)
- gold/brass  `#e9a94d`  (headings, primary frame accent)
- coral       `#e4594c`  (alerts, eyebrows, code left-rail)
- teal        `#3bb5ae`  (links, console accents)
- cream       `#ead9b0`  (h1, strong text, warm light)
- steel blue  `#5e8fc0`  (secondary accent)
- body text   `#ede6d6`  (warm off-white)

Persistent **LCARS frame on every slide** (drawn as chrome around the content,
never overlapping it):
- top-left rounded "elbow" in gold
- a left vertical rail of stacked rounded color blocks (gold/coral/teal/cream/steel)
- segmented top bar with a `OPENAPI-RUBY` label and a live readout `NCC · SEC nn/nn`
  (current/total slide)
- a thin segmented bottom bar with an `ENGINEERING` label
- faint starfield + grid + a warm concentric "warp core" glow in the background

Typography:
- Headings: condensed, UPPERCASE, letter-spaced, gold (Antonio/Oswald/Arial Narrow).
- Small coral UPPERCASE "eyebrow" labels above most slide titles, styled like
  console section tags (e.g. `Diagnostic // contract drift`).
- Code: monospace, dark panel with a coral left border.

## Slides (headline → on-slide content → speaker-note gist)

1. **Cover** — logo, big `openapi_ruby`, subtitle "OpenAPI docs, tests & runtime
   validation from one source — in Rails", meta line `v4.1.0 · MIT · Ruby ≥ 3.2 ·
   Rails ≥ 7`, eyebrow "Ruby Usergroup // Engineering Briefing".
   *Note: hook — "who has an API where the docs and the real API have drifted?"*

2. **Who's talking** — Marten Klitzke · Software Engineer · fobizz. Links:
   web `marten.klitzke.xyz`, GitHub `@mortik`.
   *Note: fobizz is edtech, a Rails shop, so this gem is day-job relevant.*

3. **The actual problem** — three tiny code snippets side by side showing drift:
   a serializer that stopped sending `email`; an `openapi.yaml` still listing
   `email` as required; a request spec that only asserts `have_http_status(:ok)`
   and never looks at the body. Caption: "All three are green. The docs still
   promise a field the API stopped sending."
   *Note: one contract written three times, all green, silently disagreeing.*

4. **What is OpenAPI?** — one line "Your API — as a document." + a small YAML
   snippet (`paths → get → 200 → schema $ref`).
   *Note: brief 101; formerly Swagger; machine-readable; watch the `$ref` strings.*

5. **OpenAPI on Rails: pick your poison** — four short cards: Hand-write the YAML ·
   Annotate controllers (apipie) · Grape + grape-swagger · Generate from tests
   (rswag + committee).
   *Note: no single status quo; openapi_ruby targets the test-driven route.
   Honest aside: rswag is 3.0-only (3.1 open since 2021) and "seeking maintainers".*

6. **openapi_ruby** (section divider) — three chips: `01 Components` (schemas as
   Ruby classes) · `02 Generation` (spec from tests) · `03 Validation` (runtime
   middleware).
   *Note: one gem, three jobs; all read one definition via one engine (json_schemer).*

7. **Subsystem 01 — schema components** — a `Schemas::User` Ruby class including
   `OpenapiRuby::Components::Base` with a `schema(...)` block.
   *Note: schemas as classes; autoloaded; camelCased output; covers all component types.*

8. **Because they're classes, they compose** — two code blocks: inheritance
   (`class Schemas::AdminUser < Schemas::User`) and class refs (`schema Schemas::User`
   instead of `"$ref" => "#/components/schemas/User"`).
   *Note: deep-merge inheritance; class refs = NameError on typo, jump-to-definition.*

9. **Subsystem 02 — the spec comes from tests** — the RSpec `path / get / response
   / run_test!` block (with progressive line highlights).
   *Note: the block is BOTH the doc source AND the test; run_test! fires a real request.*

10. **Two ways to write it** — two columns from the same endpoint. Style 1
    (`path` / `run_test!`, interleaved) vs Style 2 (`api_path` with schema up top +
    a separate `assert_api_response` test). Eyebrow: "RSpec: either · Minitest:
    style 2 · same output".
    *Note: same spec either way; Style 2 is the Minitest DSL — first-class, not bolted on.
    Backup detail for Q&A: a class may declare several `api_path`s; since 4.1.0 an
    ambiguous match raises `AmbiguousApiPath` instead of guessing.*

11. **Test in, spec out** — left: the test you wrote (Ruby); right: the generated
    OpenAPI (YAML) with `Schemas::User` resolved to a `$ref`. Caption: "Produced by
    `rake openapi_ruby:generate` — an explicit step, never a side effect of tests."
    *Note: zero YAML hand-written; passing test means the doc is verified, not just generated.*

12. **Subsystem 03 — runtime validation** — the `OpenapiRuby.configure` block with
    `request_validation` / `response_validation` (`:enabled | :disabled | :warn_only`),
    plus one line: `bad request → 400 · bad response → 500`.
    *Note: Rack middleware; off by default; roll out with :warn_only.*

13. **Also derived from the same components** — two code blocks: strong params
    (`openapi_permit(Schemas::UserInput)`) and Swagger UI (`mount OpenapiRuby::Engine`
    + `config.ui_enabled = true`).
    *Note: freebies from one contract; permit list from schema; docs UI is opt-in.*

14. **Why it can't drift** — three big gold lines revealed one at a time:
    "Define it once." / "Same checks in tests and prod." / "Docs are your passing tests."
    *Note: the payoff — docs, tests, validation are three views of one definition
    (json_schemer is the shared engine).*

**Close** — a clean slide: large "Thank you" + "Questions?". Nothing else.

## Output
Produce the deck as [state your target: e.g. Slidev markdown / reveal.js HTML /
a Figma-style layout spec / Keynote outline]. Keep the LCARS frame consistent on
every slide, put all prose in speaker notes, and keep code blocks verbatim.
