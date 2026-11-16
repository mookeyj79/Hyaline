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
wallpapers/                 found backdrop images, thumbnails, and credits (README.md)
palette/palette.json        every color, for both variants (source of truth for values)
Ports/ports.json            category names, planned ports, and unlisted folders for the ports page
Ports/<app_name>/
  port.json                 name, category, tier, platforms, icon credit (feeds the ports page)
  icon.svg                  optional single-color card icon (ADR 0007)
  values.json               optional per-variant app values that are not colors ({{port.<key>}})
  site.json                 what the Pages site publishes from this port (only the preview has one)
  template/                 files with {{role}} placeholders, no raw colors
  dist/dark/                generated output, committed
  dist/light/               generated output, committed
  README.md                 step-by-step install guide for users: tier, known limits, sources
  MAPPING.md                role mapping, trade-offs, and research notes, for maintainers
build/lib/                  the rules, as modules the scripts share:
  Palette.psm1              loads and validates the palette; filters, wash, contrast
  Placeholders.psm1         the {{...}} grammar: resolves, lists problems, reads template files
  Build.psm1                renders a port into dist/ and compares a build with dist/
  Catalog.psm1              finds ports, validates port.json, ports.json, icons, site.json
  Wallpaper.psm1            wallpaper rules: grades, variant marks and pairs, license
build/build.ps1             palette + templates = dist
build/check.ps1             runs the rules: palette, contrast, structure, port list, raw color,
                            placeholders, drift, leftovers, file format, em dashes
build/test.ps1              tests the build/lib modules on small fixtures
build/site.ps1              assembles the GitHub Pages site and the port list into _site/
build/icon.ps1              finds and fetches a port's card icon
build/wallpaper.ps1         finds, checks, and adds wallpapers from Wikimedia Commons
build/setup-linux.sh        installs pwsh and chromium on a fresh Linux sandbox
.githooks/pre-commit        runs test.ps1 and check.ps1 before a commit (git config core.hooksPath .githooks)
.claude/skills/new-port/    the new-port skill and the port README template
.claude/skills/port-icon/   the port-icon skill
.claude/skills/wallpaper/   the wallpaper skill
```

## Rules that are never broken

1. **No color values outside `palette/palette.json`.** Templates use `{{role}}` placeholders only. This includes hex, rgb(), hsl(), and named colors. The one exception is wallpapers, which are image assets (ADR 0012). Port icons are not an exception: they use `currentColor` only (ADR 0007).
2. **Never invent a color.** If a port needs something the palette lacks, stop and propose a palette change to the user. Do not approximate.
3. **Never edit files in `dist/` by hand.** Change the template or the palette, then rebuild.
4. **Both variants or neither.** If the app supports only one mode, ship that one and say so in the port README.
5. **Roles keep their meaning.** Red is failure, green is success, yellow is change, and so on, per PHILOSOPHY.md. Do not reassign a role because it looks nicer.
6. **Do not guess an app's theme format.** Look it up in the app's official docs and link the source in the port README.
7. **Every port gets its own folder and its own README.** The folder is `Ports/<app_name>/`. The README is a step-by-step install guide. A `port.json` lists it on the ports page; never list ports by hand in the root README.

## When asked for a new theme or port

Requests look like "create a Windows theme" or "make a theme for Typora". Use the `new-port` skill (`/new-port <app_name>`). It covers research, tier choice, role mapping, templates, build, checks, and the install guide.

Studying how Catppuccin, Nord, Dracula, and other themes ported to the same app is expected, per PHILOSOPHY.md. Borrow their method, never their colors.

## When asked to change a color

1. Edit `palette/palette.json` only.
2. Bump `meta.version` per "Changing the palette" in PHILOSOPHY.md.
3. Run the build, then the checks.
4. Summarize which ports changed, from the build's per-port line (`changed`, `version stamp only`, `unchanged`).

## Commands

```
pwsh build/build.ps1                     # rebuild every port
pwsh build/build.ps1 -Port <app_name>    # rebuild one port
pwsh build/check.ps1                     # run all checks (CI runs this too)
pwsh build/test.ps1                      # test the build modules (CI runs this too)
pwsh build/site.ps1                      # assemble the Pages site into _site/
pwsh build/icon.ps1 -Search <words>      # find a card icon (see the port-icon skill)
pwsh build/wallpaper.ps1 -Search <words> # find a wallpaper (see the wallpaper skill)
bash build/setup-linux.sh                # pwsh or chromium missing? run this first
gh run list --workflow pages.yml -L 1    # after a merge to main, watch this until the deploy is green
```

Run build and check before every commit that touches `palette/` or `Ports/`. Run the tests too when `build/` changes.

## Template placeholders

The placeholder table (`{{role|wash}}`, `{{ansi.<slot>}}`, `{{port.<key>}}`, and the rest) is in CONTRIBUTING.md, step 4 of "Add a port". `build/lib/Placeholders.psm1` is the source of truth, and `check.ps1` fails if that table misses a filter.

Surface roles come in pairs: `chrome`, `panel`, and `raised` are translucent, `chrome_flat`, `panel_flat`, and `raised_flat` are the solid fallbacks. Use the flat ones anywhere the app cannot blur. Chrome (title bars, tabs, sidebars) carries `text` and solid accent fills only; everything else goes on `panel`.

## Working style

- Work on a branch named `port/<app_name>`, `palette/<change>`, or `build/<change>` for tooling and docs. Do not commit to `main` directly.
- Do not install a theme on the user's machine or change system settings unless asked. Building files in the repo is the job.
- Screenshots cannot be generated here. Ask the user to add them, and add the screenshot table to the port README only once the files exist.
- READMEs are for their readers: a port README for the person installing it, the root README for a visitor. No measurements, role names, palette versions, ADR links, research notes, or notes to an agent in them.
- Writing style for docs: plain and short. `check.ps1` fails on em dashes.

## Agent skills

### Issue tracker

Issues live in GitHub Issues on `mookeyj79/Hyaline`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Uses the five default triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
