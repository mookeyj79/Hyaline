# Contributing to Hyaline

Thanks for helping. Hyaline only works if every port looks like it belongs to the same machine, so the rules below are strict. Read [PHILOSOPHY.md](PHILOSOPHY.md) first: it is the source of truth for every design decision.

## Ways to help

- **Port Hyaline to an app.** See [Add a port](#add-a-port).
- **Fix a port** that looks wrong, is out of date, or has unclear install steps.
- **Suggest a wallpaper.** See [Add a wallpaper](#add-a-wallpaper).
- **Propose a palette change.** See [Change the palette](#change-the-palette).
- **Report a problem** in [GitHub Issues](https://github.com/mookeyj79/Hyaline/issues). Include the app, its version, the variant, and a screenshot.

## Rules every port follows

1. **No color values outside `palette/palette.json`.** Templates use `{{role}}` placeholders only. No hex, `rgb()`, `hsl()`, or named colors. Wallpapers are the one exception ([ADR 0003](docs/adr/0003-wallpapers-are-found-images.md)).
2. **Never invent a color.** If a port needs something the palette lacks, open an issue proposing a palette change.
3. **Never edit `dist/` by hand.** Change the template or the palette, then rebuild.
4. **Both variants or neither.** If the app supports only one mode, ship that one and say so in the port README.
5. **Roles keep their meaning.** Red is failure, green is success, yellow is change. Do not reassign a role because it looks nicer.
6. **Do not guess an app's theme format.** Follow the app's official docs and link them in the port README.
7. **Every port gets its own folder and its own README**, written as a step-by-step install guide.

Studying how Catppuccin, Nord, Dracula, and other themes ported to the same app is expected. Borrow their method, never their colors, and credit them if you reuse more than the basic structure.

## Add a port

The quickest way is [Claude Code](https://claude.com/claude-code): open the repo and run `/new-port <app_name>`. The steps it follows are in [`.claude/skills/new-port/SKILL.md`](.claude/skills/new-port/SKILL.md), and they work by hand too:

1. **Research** the app's theme format, install path, light and dark support, translucency, and where it sets its font. Use official docs.
2. **Pick a tier**: 1 Full glass, 2 Flat, or 3 Minimal (see [PHILOSOPHY.md](PHILOSOPHY.md#port-tiers)).
3. **Map every color slot to a role.** Use `chrome` for the frame (title bars, tabs, sidebars) and `panel` for content. Follow the syntax and terminal mappings in PHILOSOPHY.md.
4. **Write the template** in `Ports/<app_name>/template/`, using these placeholders:

   | Placeholder | Output |
   |---|---|
   | `{{role}}` | `#rrggbb` |
   | `{{role\|nohash}}` | `rrggbb` |
   | `{{role\|rgb}}` | `r, g, b` |
   | `{{role\|rgba}}` | `rgba(r, g, b, a)` using the role's alpha |
   | `{{role\|hexa}}` | `#rrggbbaa` using the role's alpha |
   | `{{role\|percent}}` | the role's alpha as a whole percent, `0` to `100` |
   | `{{role\|wash}}` | `#rrggbbaa` using the variant's `wash` alpha, for see-through highlights |
   | `{{role\|washflat}}` | `#rrggbb`, the wash laid over `panel_flat`, for apps that take solid colors only |
   | `{{role\|clear}}` | `#rrggbb00`, fully transparent, for app settings that can only be switched off with a color |
   | `{{ansi.<slot>}}` | the role for a terminal ANSI slot per ADR 0001 (`black` to `white`, `bright_<slot>`), takes the same filters |
   | `{{meta.name}}`, `{{variant.name}}`, `{{variant.mode}}` | theme name, variant name, `dark` or `light` |
   | `{{meta.repository}}` | the repo URL |
   | `{{port.<key>}}` | a per-variant app value that is not a color, from `Ports/<app_name>/values.json` (`{ "dark": { "<key>": "..." }, "light": { ... } }`) |

5. **Build and check**:

   ```sh
   pwsh build/build.ps1 -Port <app_name>
   pwsh build/check.ps1
   ```

6. **Write the README** from [`port-readme-template.md`](.claude/skills/new-port/port-readme-template.md). Fill in every section, including **Set the font**.
7. **Add screenshots** of both variants to `Ports/<app_name>/screenshots/`.
8. **List the port** on the [ports page](https://mookeyj79.github.io/Hyaline/ports/) by adding `Ports/<app_name>/port.json`:

   ```json
   {
     "name": "Windows Terminal",
     "category": "terminal",
     "tier": 1,
     "platforms": ["windows"]
   }
   ```

   `category` is one of the ids in [`Ports/ports.json`](Ports/ports.json). `platforms` takes `windows`, `macos`, `linux`, and `web`. An optional `monogram` (1 to 3 characters) replaces the initials on the card. If the app was in `planned` in `Ports/ports.json`, remove it from there. `check.ps1` enforces all of this.
9. **Add a card icon** (optional). Icons are single-color SVGs that take their color from the page ([ADR 0007](docs/adr/0007-port-icons-are-single-color.md)). Use the app's brand mark from Simple Icons if the app allows its mark to be shown, or else a Lucide glyph for what the app is:

   ```sh
   pwsh build/icon.ps1 -Search "<app name>"
   pwsh build/icon.ps1 -Port <app_name> -Glyph <name>
   pwsh build/icon.ps1 -Port <app_name> -Brand <slug> -Mark <url showing the mark may be used>
   ```

   The script writes `Ports/<app_name>/icon.svg` and prints an `"icon"` credit to paste into `port.json`. Without an icon, the card shows the monogram.

## Change the palette

1. Edit `palette/palette.json` only.
2. Bump `meta.version`: patch for a tuned value, minor for a new role, major for a role whose meaning changed or was removed.
3. Run the build and the checks. Every port rebuilds.
4. Retake the preview screenshots (below), since they show the palette.
5. For a new role or a changed meaning, add an ADR in [`docs/adr/`](docs/adr/) explaining why.

## Add a wallpaper

Follow the checklist in [`wallpapers/README.md`](wallpapers/README.md#adding-a-wallpaper). In short: a license that allows redistribution (CC0 or public domain is simplest), the unmodified original, a 640 px thumbnail, full credits, and a contrast check behind both variants.

## Retake the preview screenshots

The README and the preview port show screenshots from `Ports/preview/screenshots/`. Retake them after a palette or preview change. From the repo root, serve the repo and capture each variant with a headless Chromium:

```sh
python3 -m http.server 8765
chromium --headless=new --hide-scrollbars --window-size=1280,960 --virtual-time-budget=15000 \
  --screenshot=dark.png http://127.0.0.1:8765/Ports/preview/dist/dark/index.html
```

Repeat for `light`. Save them as `dark.jpg` and `light.jpg`. The section thumbnails (`mermaid.jpg`, `roles.jpg`, `font.jpg`) are crops of a taller capture (`--window-size=1280,6400`).

## Branches and pull requests

- Branch names: `port/<app_name>` for ports, `palette/<change>` for palette changes. Never commit to `main` directly.
- Run `pwsh build/build.ps1` and `pwsh build/check.ps1` before every commit that touches `palette/` or `Ports/`. CI runs the same checks on every pull request.
- Show both variants in the pull request: screenshots, or the generated files for apps that cannot be screenshotted.

## Writing style

Plain and short. Numbered steps, one action each. Real paths and real menu names. No em dashes.

## License

By contributing, you agree your work is released under the [MIT License](LICENSE). Third-party assets (wallpapers, fonts) must have a license that allows redistribution, and that license and its credit must be recorded next to the asset.
