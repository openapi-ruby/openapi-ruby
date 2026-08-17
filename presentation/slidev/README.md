# openapi_ruby — Slidev deck

Slidev source port of the LCARS talk deck.

## Run

```bash
npm install -g @slidev/cli   # or: npx
cd slidev
slidev slides.md             # dev server + presenter view (speaker notes)
```

## Export

```bash
slidev export slides.md                 # -> slides-export.pdf
slidev export slides.md --format pptx    # -> .pptx
slidev export slides.md --with-clicks    # keep click steps
```
(Export needs Playwright chromium: `npx playwright install chromium`.)

## Notes / caveats

- **Aspect ratio** is 16:9 by default (matches the 1920×1080 original). Font
  sizes in `slides.md` are authored for that canvas.
- **Speaker notes** are the `<!-- ... -->` block at the end of each slide —
  they show in Slidev's presenter view (press `p`).
- **The LCARS frame** is repeated as a small HTML block at the top of every
  slide. The `NCC · SEC nn/15` readout is hand-set per slide. To make it live,
  replace the `<div class="readout">…</div>` with a Vue expression:
  `NCC · SEC {{ ($slidev.nav.currentPage).toString().padStart(2,'0') }}/{{ $slidev.nav.total }}`
  (Slidev renders Vue in markdown when `mdc: true`).
- **Fonts**: Barlow + JetBrains Mono come via the frontmatter `fonts:` field;
  Antonio (headings) is pulled in through the `@import` in the first `<style>`
  block.
- **Code highlighting**: uses Shiki. The coral left-rail panel styling is in
  the same `<style>` block and applies to every fenced code block.
