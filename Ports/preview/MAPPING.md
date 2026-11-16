# Preview: how it is built

For maintainers. The user-facing page description is [README.md](README.md).

The preview is not an app theme. It is treated as a port so it gets the same build and checks as every other port, and so its colors can never drift from the palette. It declares Tier 1 (full glass). The site also holds the ports page (`ports.html`). The preview itself is not listed there, since it is not an app port (`unlisted` in `Ports/ports.json`).

## Screenshots

`screenshots/` is taken with headless Chromium at 1280 × 960. Retake them when the palette or the page changes (see CONTRIBUTING.md).

## Build and view locally

1. Run `pwsh build/build.ps1 -Port preview` from the repo root.
2. Open `Ports/preview/dist/dark/index.html` or `Ports/preview/dist/light/index.html` in a browser.
3. For the ports page, run `pwsh build/site.ps1` and open `_site/ports/index.html`. The port list (`ports.js`) only exists in the assembled site.

## How it is built

- `template/theme.css` holds every role as a CSS variable, scoped to `:root[data-variant="<mode>"]`. The build renders it once per variant. Chrome and panel also get their clamp (`{{chrome|clamp}}`, `{{panel|clamp}}`) and thin tint (`{{chrome|clamptint}}`, `{{panel|clamptint}}`), so the page holds no blur, filter, or alpha numbers of its own.
- `template/base.css` holds what both pages share: fonts, surfaces, the glass, the edge, the top bar, and the variant switch.
- `template/ports.html` reads the port list from `ports.js`, which `build/site.ps1` generates from every `Ports/<app>/port.json` and `Ports/ports.json`. Variants on each card come from which `dist/` folders exist. Tier and platform names come with the list too.
- `site.json` tells `build/site.ps1` what to publish: the folders to copy, and the site entry pages (`/` and `/ports/`) that open a page in the visitor's variant.
- `template/index.html` loads both `../dark/theme.css` and `../light/theme.css`, so the switch repaints instantly without a reload. Without JavaScript, the switch links to the other variant's page.
- Mono text uses the recommended font, FiraCode Nerd Font Mono, from `assets/fonts/`. Those files are trimmed to the characters the page uses (Latin, ligatures, and the icons shown), so they total about 90 KB instead of 5 MB.
- The page itself holds no color values. The role values and contrast ratios in the Roles section are read from the CSS variables at runtime.
- Text never sits directly on the backdrop. Everything is on a panel, so text reads over any backdrop.
- The backdrop follows the variant: the `backdrop` role, under a wallpaper marked for that variant in `wallpapers/README.md` (Light or Both). The pick is `wallpaper` in `values.json`, a CSS value (`url(...)` relative to the repo root, or `none`). Light uses `white-sands-dunes.jpg`. No wallpaper is marked Dark or Both yet, so Dark shows the backdrop color alone; when one is added, set it in `values.json` and rebuild. The page is not self-contained: it needs the repo layout (or the Pages site, which keeps it).

## Glass and edge

- Glass (ADR 0008). Where the browser has `backdrop-filter`, chrome and panel use the clamp: blur, contrast, brightness, and saturate from the palette's `clamp` block, under the thin tint. The panel is clamped harder than the chrome. Without `backdrop-filter` (checked with `@supports`), they fall back to the dense `chrome` and `panel` tint alone, which passes over any backdrop. `raised` sits on the glass at its own alpha, with no filter.
- Edge (ADR 0009). A 1 px inset hairline in `edge` (translucent, since every surface here is glass) on the top inside of the top bar, window title bars, ports page headings, and raised surfaces. Every panel and window has a 1 px outline: `edge` in Dark, `line` in Light.
- In Light, `edge` is white on white raised surfaces, so `line` carries the lift instead: raised surfaces with a `line` border keep just that, and the borderless ones (tabs, address bars) get a 1 px `line` ring. The per-variant switch is `--outline`, `--lift`, and `--lift-ring` in `base.css`.
- `edge_flat` has no surface to sit on here (the only flat surface is the Mermaid diagram, which has its own border). It is shown in the Roles section.

## Publish with GitHub Pages

`.github/workflows/pages.yml` runs `build/site.ps1` and deploys `_site/` on every push to `main`. The root page and `/ports/` open the variant matching the visitor's OS setting.

To turn it on once:

1. On GitHub, open the repo **Settings**, then **Pages**.
2. Under **Build and deployment**, set **Source** to **GitHub Actions**.

## Update it

- Colors: change `palette/palette.json` and rebuild. The page follows.
- Content or layout: edit `template/index.html`, then run the build and the checks.
- Never edit `dist/` by hand.

## Role mapping

| Page element | Role |
|---|---|
| Page background | `backdrop`, under the variant's wallpaper |
| Top bar, window title bars, ports page headings | `chrome` (clamped), primary `text` only |
| Cards, window contents | `panel` (clamped harder) |
| Tabs, address bars, inputs, tiles, callouts | `raised` |
| Top inside of chrome and raised, window outline (Dark) | `edge` |
| Window outline and raised lift (Light) | `line` |
| Borders, dividers, meter tracks | `line` |
| Headings, content | `text` |
| Body copy, punctuation | `text_dim` |
| Metadata, comments, timestamps | `text_muted` |
| Links, focus, cursor, status bar, selected switch, primary button | `accent` with `on_accent` |
| Failed, removed, errors, destructive button | `red` |
| Passed, added, healthy | `green` |
| Warnings, modified, decorators | `yellow` |
| Running, info, functions and keys | `blue` |
| Planned, keywords, constants | `magenta` |
| Paths, types, tags | `cyan` |
| Numbers, flags, inline code | `orange` |

## Mermaid mapping

Mermaid's `base` theme, with `themeVariables` filled from the roles at runtime. Every variable the flowchart and sequence diagram read is set, so Mermaid does not lighten or darken anything on its own.

| Mermaid variables | Role |
|---|---|
| `background`, `clusterBkg`, `edgeLabelBackground`, `tertiaryColor` | `panel_flat` |
| `primaryColor`, `mainBkg`, `actorBkg`, `noteBkgColor`, `labelBoxBkgColor`, `activationBkgColor` | `raised_flat` |
| Node, actor, and label box borders | `text_muted` (they carry meaning, so 3:1) |
| `clusterBorder`, `actorLineColor`, `tertiaryBorderColor` | `line` |
| All text | `text` |
| `lineColor`, `arrowheadColor`, `signalColor`, `titleColor`, `loopTextColor` | `text_dim` |
| `noteBorderColor` | `yellow` (annotation) |
| `activationBorderColor` | `blue` (in progress) |
| `errorTextColor` | `red` |
| Status classes `ok`, `fail`, `warn`, `active`, `planned` | border in `green`, `red`, `yellow`, `blue`, `magenta`; fill stays neutral |

Diagrams use the flat roles because Mermaid draws solid SVG fills.

Status is never color alone: every status also has a word (passed, failed, running, planned) or a symbol.

## Gaps and trade-offs

- Content glass is the clamped panel, or the dense `panel` tint where the browser has no `backdrop-filter`. `check.ps1` measures both over pure black and pure white. The clear glass is in the chrome.
- The roles table measures contrast against `panel_flat`, not the glass.
- No panel shadow. PHILOSOPHY.md allows one soft shadow, but the palette has no shadow role. Adding one is a palette change.
- Display and body fonts load from Google Fonts. Offline, the page falls back to system fonts. The mono font is bundled and works offline.
- Mermaid loads from jsDelivr (pinned to 11.4.1). Offline, the diagram source is shown as text instead.
- Only flowchart and sequence diagram variables are mapped. Other diagram types (pie, gantt, git graph, mindmap) have their own color slots and would still get Mermaid's derived colors. A full `Ports/mermaid/` port should map those and share this table.

## Research

- Layout grew out of a theme comparison mockup made while choosing Hyaline's direction. No other theme's colors are used.
- The bundled font subset was made with fontTools.
