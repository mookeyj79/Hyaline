# Hyaline

*hyaline (HY-uh-lin): glassy, clear like glass.*

Smoke by night, frost by day. One theme, two variants, the same look in every app.

| Variant | Mode | Look |
|---|---|---|
| **Hyaline Dark** | Dark | Smoked, frosted panels with light text |
| **Hyaline Light** | Light | Frosted white panels with dark ink |

**[See it first: the preview page](https://mookeyj79.github.io/Hyaline/)** shows mock apps, every role, and contrast in both variants. Source in [`Ports/preview/`](Ports/preview/).

<!-- Add a hero screenshot here once the first ports exist:
![Hyaline Dark and Hyaline Light](assets/preview.png)
-->

## Why

I want every tool I use to look like it belongs to the same machine. Hyaline is a single palette with strict rules about what each color means, plus a port for each app generated from that palette. Change a color once and every port updates.

## Status

Early. The design rules are written, the palette and first ports are in progress.

## Ports

| App | Tier | Status |
|---|---|---|
| Windows Terminal | 1 Full glass | Planned |
| Starship | 2 Flat | Planned |
| VS Code | 2 Flat | Planned |
| Typora | TBD | Planned |
| Windows | TBD | Planned |

Each port lives in its own folder, `Ports/<app_name>/`, with its own README: a step-by-step install guide.

### Tiers

Not every app can do glass. Each port says how far it gets:

- **Tier 1, Full glass**: full palette, translucency, and blur
- **Tier 2, Flat**: full palette on solid surfaces, no blur
- **Tier 3, Minimal**: background, accent, and status colors only

## How it works

```
palette/palette.json          every color, for both variants
Ports/<app_name>/template/    theme files with {{role}} placeholders
Ports/<app_name>/dist/        generated themes, ready to use
build/                        turns palette + templates into dist
```

- **The palette is the only place colors live.** Templates name a role (`panel`, `text`, `accent`, `red`), never a hex value.
- **Generated files are committed.** You can grab a theme from `dist/` without building anything.
- **CI catches drift.** The build runs on every change and fails if a committed theme does not match the palette.

## Font

Hyaline recommends **[FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads)**: monospaced, with programming ligatures and the icons that shell prompts and file trees use. Every port's install guide says where to set it in that app.

1. Download [FiraCode.zip](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip) from the Nerd Fonts release.
2. Unzip it and install the fonts:
   - **Windows**: select the `.ttf` files, right-click, and choose **Install for all users**.
   - **macOS**: `brew install --cask font-fira-code-nerd-font`, or double-click each `.ttf` and choose **Install Font**.
   - **Linux**: copy the `.ttf` files to `~/.local/share/fonts/` and run `fc-cache -f`.
3. In each app, pick **FiraCode Nerd Font Mono**. The Mono version keeps every icon one cell wide, so columns always line up. If an app lists only **FiraCode Nerd Font**, that works too.

Free under the SIL Open Font License. See [ADR 0005](docs/adr/0005-recommended-font.md).

## Install a port

1. Open `Ports/<app_name>/README.md`.
2. Take the file from `dist/dark/` or `dist/light/`.
3. Follow the install steps there.

## Build

Requires PowerShell 7.

```
pwsh build/build.ps1                     # rebuild every port
pwsh build/build.ps1 -Port <app_name>    # rebuild one port
pwsh build/check.ps1                     # drift, raw color, and contrast checks
```

## Add a port

This repo is set up for [Claude Code](https://claude.com/claude-code). Open it there and ask:

> Can you make a theme for Typora?

or run `/new-port typora`. The `new-port` skill looks up the app's theme format, picks a tier, maps the app's settings to palette roles, builds both variants, runs the checks, and writes the port README.

Doing it by hand works too. Read [PHILOSOPHY.md](PHILOSOPHY.md) first, then follow the steps in `.claude/skills/new-port/SKILL.md`.

## Design rules

[PHILOSOPHY.md](PHILOSOPHY.md) covers what each color means, how surfaces layer, the contrast floor, and what a port must never do. It also says that studying how Catppuccin, Nord, and other themes built their ports is expected. The short version:

1. Sameness beats perfection.
2. Roles, not colors.
3. The palette is mandatory, blur is a bonus.
4. Calm surface, loud signal.
5. Readable first.
6. Two variants, one theme.

## License

[MIT](LICENSE)
