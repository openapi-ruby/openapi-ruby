# openapi_ruby — Usergroup talk

A ~15–20 min [Slidev](https://sli.dev) presentation introducing `openapi_ruby`.

## Run it

```bash
cd presentation
pnpm install
pnpm dev         # opens http://localhost:3030
```

Uses pnpm, pinned via mise (`.tool-versions` → `pnpm 10.28.1`) and
`packageManager` in `package.json`. `mise install` provisions it; then bare
`pnpm` resolves inside this folder.

## Presenting

- Press `f` for fullscreen, `o` for slide overview.
- Speaker notes are the `<!-- ... -->` block under each slide — open the
  **presenter view** (`/presenter` on the URL, or the "person" icon) to read
  them on a second screen.
- Arrow keys / space advance.

## Export

```bash
pnpm build        # static site into dist/
pnpm export       # slides.pdf (needs playwright-chromium)
```

## Theme

A self-contained LCARS (Star Trek: Strange New Worlds) theme, tuned to the
ruby-red logo palette. No theme package (`theme: none`) — it's all in
`style.css`, which Slidev auto-loads:

- `style.css` defines the palette (`--gold`, `--coral`, `--teal`, `--cream`,
  `--steel` on a deep navy `--bg`), the `.slidev-layout` background, and the
  LCARS frame.
- The LCARS frame (elbow, side rail, segmented bars) is a small HTML block
  repeated at the top of every slide. The `NCC · SEC nn/nn` readout is **live**
  via `$slidev.nav` (works because `mdc: true`).
- `canvasWidth: 1920` — px sizes are authored against a 1920×1080 canvas.
- Fonts: Barlow + JetBrains Mono via the `fonts:` frontmatter; Antonio (headings)
  via an `@import` at the top of `style.css`. **That `@import` needs network** —
  for a fully offline export, self-host it or add it to `fonts:`.

Tune colors via the `--*` CSS variables at the top of `style.css`.

> This deck was generated from `DESIGN_PROMPT.md`.

## Style: hybrid-minimal

Slides are deliberately sparse — one idea or one code block each, no
explanatory prose on the slide. **The content lives in the speaker notes**
(the `<!-- ... -->` block under each slide), written in a casual talk voice.
Open presenter view to read them while presenting. This style leans hard on
delivery and makes a weak leave-behind — the notes are essential.

## Structure (15 slides)

1. Title
2. Speaker — Marten Klitzke / fobizz
3. Contract drift — one contract, written three times
4. What is OpenAPI? (brief 101)
5. OpenAPI on Rails: pick your poison (the landscape)
6. openapi_ruby — one gem, three jobs
7. **Components** — schemas as Ruby classes
8. **Composition** — inheritance + class refs
9. **Generation** — the spec comes from your tests
10. Two ways to write it (RSpec styles; Minitest)
11. Test in, spec out — the payoff (`rake openapi_ruby:generate`)
12. **Validation** — runtime middleware
13. Also derived — strong params + Swagger UI
14. Why it can't drift — define once; same checks in tests & prod; docs from passing tests
15. Thank you / Questions

Edit `slides.md` to adjust content; the GitHub handle lives on the speaker slide.
