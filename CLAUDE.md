# Theme ports repo

This repo holds one color theme and every app port of it. The theme has two variants that always ship together:

- **Hyaline Dark** (dark): smoked, frosted panels with light text
- **Hyaline Light** (light): frosted white panels with dark ink

The theme's family name lives in `palette/palette.json` under `meta.name`. Read it from there. Never hardcode it.

The design rules are in PHILOSOPHY.md. They are binding, not background reading:

@PHILOSOPHY.md

## Layout

```
PHILOSOPHY.md               design rules (source of truth for decisions)
GLOSSARY.md                 project terms
docs/adr/                   recorded decisions and why
wallpapers/                 found backdrop images with credits (planned, issue #1)
palette/palette.json        every color, for both variants (source of truth for values)
Ports/<app_name>/
  template/                 files with {{role}} placeholders, no raw colors
  dist/dark/                generated output, committed
  dist/light/               generated output, committed
  README.md                 step-by-step install guide, plus tier, role mapping, known gaps, sources
build/build.ps1             palette + templates = dist
build/check.ps1             drift, raw-hex, placeholder, and contrast checks
.claude/skills/new-port/    the new-port skill and the port README template
```

## Rules that are never broken

1. **No color values outside `palette/palette.json`.** Templates use `{{role}}` placeholders only. This includes hex, rgb(), hsl(), and named colors. The one exception is wallpapers, which are image assets (ADR 0003).
2. **Never invent a color.** If a port needs something the palette lacks, stop and propose a palette change to the user. Do not approximate.
3. **Never edit files in `dist/` by hand.** Change the template or the palette, then rebuild.
4. **Both variants or neither.** If the app supports only one mode, ship that one and say so in the port README.
5. **Roles keep their meaning.** Red is failure, green is success, yellow is change, and so on, per PHILOSOPHY.md. Do not reassign a role because it looks nicer.
6. **Do not guess an app's theme format.** Look it up in the app's official docs and link the source in the port README.
7. **Every port gets its own folder and its own README.** The folder is `Ports/<app_name>/`. The README is a step-by-step install guide.

## When asked for a new theme or port

Requests look like "create a Windows theme" or "make a theme for Typora". Use the `new-port` skill (`/new-port <app_name>`). It covers research, tier choice, role mapping, templates, build, checks, and the install guide.

Studying how Catppuccin, Nord, Dracula, and other themes ported to the same app is expected, per PHILOSOPHY.md. Borrow their method, never their colors.

## When asked to change a color

1. Edit `palette/palette.json` only.
2. Run the build, then the checks.
3. Summarize which ports changed.
4. Bump `meta.version`: patch for a tuned value, minor for a new role, major for a role whose meaning changed or was removed.

## Commands

```
pwsh build/build.ps1                     # rebuild every port
pwsh build/build.ps1 -Port <app_name>    # rebuild one port
pwsh build/check.ps1                     # run all checks (CI runs this too)
```

Run both before every commit that touches `palette/` or `Ports/`.

## Template placeholders

| Placeholder | Output |
|---|---|
| `{{role}}` | `#rrggbb` |
| `{{role\|nohash}}` | `rrggbb` |
| `{{role\|rgb}}` | `r, g, b` |
| `{{role\|rgba}}` | `rgba(r, g, b, a)` using the role's alpha |
| `{{meta.name}}`, `{{variant.name}}`, `{{variant.mode}}` | theme name, variant name, `dark` or `light` |

Surface roles come in pairs: `panel` and `raised` are translucent, `panel_flat` and `raised_flat` are the solid fallbacks. Use the flat ones anywhere the app cannot blur.

## Bootstrap

If `palette/palette.json`, `build/build.ps1`, or `build/check.ps1` do not exist yet, the repo is new. Tell the user what is missing and offer to create it before starting any port. Build them to match this file:

- **Palette**: `meta` (name, version) plus `variants.dark` and `variants.light`. Each variant has `name`, `mode`, and `roles`. Roles: `backdrop`, `panel`, `panel_flat`, `raised`, `raised_flat`, `line`, `text`, `text_dim`, `text_muted`, `accent`, `on_accent`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `orange`. A role is a hex string, or an object with `hex` and `alpha` for translucent surfaces.
- **Build**: PowerShell 7, no external modules. For each port, render every file in `template/` once per variant into `dist/<variant>/`, keeping file names and structure. Fail on an unknown placeholder.
- **Check**: fail if `dist/` differs from a fresh build, if any template contains a raw color value, if any `dist/` file contains `{{`, or if text roles fall below the contrast floor in PHILOSOPHY.md against `panel_flat`.

Do not pick palette values yourself. Ask the user for them.

## Working style

- Work on a branch named `port/<app_name>` or `palette/<change>`. Do not commit to `main` directly.
- Do not install a theme on the user's machine or change system settings unless asked. Building files in the repo is the job.
- Screenshots cannot be generated here. Leave the placeholder in the port README and ask the user to add them.
- Writing style for docs: plain and short. No em dashes.

## Agent skills

### Issue tracker

Issues live in GitHub Issues on `mookeyj79/Hyaline`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Uses the five default triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
