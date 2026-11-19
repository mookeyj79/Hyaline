# Hyaline: Design Philosophy

> Draft. Hyaline (HY-uh-lin): glassy, clear like glass.

## The idea

Smoke by night, frost by day.

Hyaline is one theme with two variants:

- **Hyaline Dark** (dark): smoked, frosted panels with light text.
- **Hyaline Light** (light): frosted white panels with dark ink.

Both variants share the same roles and the same structure. Switching between them should feel like the sun went down, not like you opened a different app.

The goal of this repo is simple: every tool I use should look like it belongs to the same machine.

## Principles

1. **Sameness beats perfection.** A port that matches the others at 90% is better than a port that looks amazing on its own. When in doubt, do what the other ports do.
2. **Roles, not colors.** Ports never pick a color. They pick a role (panel, text, accent, red) and the palette decides what that looks like.
3. **Palette is mandatory, blur is a bonus.** The palette works everywhere. Blur only works where the app allows it. A port without blur is still a real port.
4. **Calm surface, loud signal.** Panels and text stay neutral. Color is reserved for things that mean something: state, syntax, focus.
5. **Readable first.** If glass makes text harder to read, the glass loses.
6. **Two variants, one theme.** Anything that exists in one variant exists in the other. No dark-only features.

## Anatomy

Every port is built from the same layers, back to front:

| Layer | What it is |
|---|---|
| **Backdrop** | Whatever is behind the app: a wallpaper, or the `backdrop` fill where there is none. Hyaline's glass is set to read well over the wallpapers it ships. Hyaline's wallpapers come in pairs where possible, one for each variant. |
| **Chrome** | The frame around content, such as title bars, tabs, toolbars, and sidebars that list only names. Clearer glass than the panel. Carries primary text and solid fills only. |
| **Panel** | The main surface, where content lives. Smoke-tinted in Dark, frost-tinted in Light. Translucent where possible. |
| **Raised** | A slightly lifted surface on top of a panel: title bars, tabs, cards, inputs. |
| **Line** | Borders and dividers. Thin, low contrast, never decorative. |
| **Edge** | A lit hairline where light catches the glass: on the top of chrome and raised surfaces, and around the window. Carries no meaning. |
| **Text** | Three strengths: primary (content), dim (supporting), muted (comments, metadata). |

### The glass

The glass is a tint and a blur, set by eye for each variant. Where the app allows blur, the tint is thinner (Dark 35% transparent, Light 40%, both with a 6.5 px blur). Where it allows only an opacity, the tint is denser (Dark 20% transparent, Light 15%). Raised surfaces are a white layer on the panel: 10% in Dark, 50% in Light. Blur is welcome but never counted on. See [ADR 0014](docs/adr/0014-the-glass-is-set-by-eye.md).

### The flat fallback

Many apps cannot do translucency. For those, the palette defines a **flat** value for each surface: the glass as it looks over a wallpaper, laid down solid. Each flat value is chosen to match the glass, not worked out from it. See [ADR 0009](docs/adr/0009-flat-is-the-glass-as-it-looks.md).

Flat is not a lesser version. It is the same theme with the window closed. The edge keeps it Hyaline.

### Chrome and content

Chrome is clearer glass than the panel, so less passes on it. The window is split:

- **Chrome** holds primary text and solid fills (accent or a color role, such as a selected tab or an active item) with `on_accent`. No dim, muted, or colored text, and no washes. A hover is `raised`.
- **Panel** holds content: code, output, documents. Every role passes there.

Chrome or content is decided by what an area shows, not its name. An area that shows dim, muted, or colored text is content and goes on the panel, wherever it sits. If an app cannot tell chrome from content, or has only one see-through surface, use `panel` everywhere. See [ADR 0010](docs/adr/0010-chrome-carries-what-passes-everywhere.md).

## Color roles

Every color has one job, and the job is the same in every port.

| Role | Means | Typical uses |
|---|---|---|
| **Accent** | "You are here" | Focus, selection, cursor, links, primary buttons |
| **Red** | Failure, removal | Errors, deletions, down, destroy |
| **Green** | Success, addition | Passing, healthy, added lines, create |
| **Yellow** | Caution, change | Warnings, modified, degraded |
| **Blue** | Information, in progress | Running jobs, info messages |
| **Magenta** | Special, planned | Keywords, constants, not-yet states |
| **Cyan** | Reference | Paths, anchors, tags, cross-links |
| **Orange** | Literal | Numbers, inline code, flags |

Accent and Blue share a hue on purpose: the thing you are focused on and the thing in progress are both "active."

### Syntax mapping

| Token | Role |
|---|---|
| Keys, properties, functions | Blue |
| Strings | Green |
| Numbers, flags | Orange |
| Keywords, booleans, constants | Magenta |
| Types, references, anchors | Cyan |
| Tags, annotations, decorators | Yellow |
| Errors, invalid | Red |
| Punctuation | Dim text |
| Comments | Muted text |

If a language has a token that does not fit, pick the closest role above. Do not add a color.

## Port tiers

Not every app can do everything. Each port declares its tier in its README.

| Tier | Name | What it delivers |
|---|---|---|
| **1** | Full glass | Complete palette on translucent surfaces, with or without blur. Also ships flat. |
| **2** | Flat | Complete palette on solid surfaces. |
| **3** | Minimal | The app only allows limited theming: background, accent, and status colors |

A port's tier is the best it delivers using settings the app or OS supports, and its README says where that holds.

A Tier 3 port is a win, not a compromise. The tier exists so "close enough" is a defined grade and not an argument to have every time.

## Contrast floor

Every solid surface must pass, measured as drawn. The glass is set by eye (ADR 0014): it is still measured over pure black and pure white and the numbers are listed, but it does not have to pass.

| On | Primary text | Dim text | Muted text | Role colors |
|---|---|---|---|---|
| Panel | 4.5 | 4.5 | 3 | 4.5 |
| Raised | 4.5 | 4.5 | 3 | 3, short labels only |
| Chrome | 4.5 | n/a | n/a | n/a |
| A wash | 4.5 | 3 | 3 | 3 |

Opacity-only glass, where the app offers a tint and one opacity, is measured the same way but has its own rows. Primary text keeps 4.5, and every other threshold is two thirds of the same row in the table above.

| On (opacity-only glass) | Primary text | Dim text | Muted text | Role colors |
|---|---|---|---|---|
| Panel | 4.5 | 3 | 2 | 3 |
| A wash | 4.5 | 2 | 2 | 2 |
| Chrome | 4.5 | n/a | n/a | n/a |

Raised surfaces are solid on opacity-only glass and keep the Raised row of the first table. See [ADR 0013](docs/adr/0013-opacity-only-glass-has-its-own-floor-rows.md).

`on_accent` on an accent fill: 4.5. Borders that mark state (focus, an active tab, an error) use a role color and need 3 against their surface. `line` and `edge` carry no meaning and have no floor.

Short labels are inline code, badges, and a tag in a tab. Running colored text, such as code, goes on the panel.

A wash is a color role at the variant's wash alpha, used for selections and diff lines. See [ADR 0006](docs/adr/0006-one-wash-alpha-for-highlights.md) and [ADR 0011](docs/adr/0011-the-contrast-floor-holds-over-any-backdrop.md).

The light variant is where this bites. Yellow and cyan get darkened until they pass. Pastels on frost are not allowed, no matter how nice they look in a swatch.

## Hard no's

- **No hex values outside the palette.** Ports reference roles only. Wallpapers are the one exception: they are image assets, not colors (ADR 0012).
- **No inventing colors in a port.** If a port truly needs a new one, it goes into the palette and becomes available to every port.
- **No single-variant ports.** Ship Dark and Light together. If an app only supports one mode, say so in the README.
- **No pure black backgrounds and no pure white text.** Smoke is not black, and nothing here should glow.
- **No decoration.** No text glow, no gradients on text, no shadows other than the single soft panel shadow.
- **No color as the only signal** where the app gives you a second one (icon, label, shape).

## Learn from other themes

Catppuccin, Nord, Dracula, Rosé Pine, and others have already ported their themes to hundreds of apps. Looking at how they did it is more than okay. It is expected.

Before starting a port, find an existing port of another theme for the same app and study it:

- Which file format and install path they use
- Which of the app's settings they found worth theming
- How they handle light and dark together
- What they could not theme, and how they worked around it

Their ports are the fastest way to learn an app's theming system, and they have already hit the problems you are about to hit.

What comes from them is the **method**. What comes from Hyaline is the **colors and the role mapping**. If a port reuses another project's files or structure beyond the basics, check that project's license and credit it in the port README.

## What every port contains

Each port lives in its own folder: `Ports/<app_name>/`.

- A **template** that references palette roles.
- **Generated output** for both variants, committed to the repo.
- A **README** that is a step-by-step install guide. Someone who has never themed the app should be able to follow it start to finish. It also states the tier and known limits.
- A **MAPPING.md** for maintainers: which role each app setting uses, and why.
- A **screenshot** of each variant.

## Changing the palette

The palette is versioned.

- **Patch**: a value is tuned. Roles and meaning unchanged.
- **Minor**: a new role is added.
- **Major**: a role changes meaning or is removed.

Every palette change rebuilds every port. CI fails if any committed output does not match the current palette.

## Settled questions

- **Bright terminal colors.** The bright six reuse their normal roles. Black and white slots map to neutral roles by brightness. See [ADR 0001](docs/adr/0001-bright-ansi-colors-reuse-normal-hues.md).
- **Accent.** One fixed blue. See [ADR 0002](docs/adr/0002-one-fixed-accent.md).
- **Backdrop.** The repo ships wallpapers: found images with a license that allows redistribution and a recorded credit, chosen by taste and marked with the variant they suit. They are the one exception to the palette rule. See [ADR 0012](docs/adr/0012-wallpapers-are-chosen-by-taste.md).
- **Font.** FiraCode Nerd Font, set in every app that allows it. See [ADR 0005](docs/adr/0005-recommended-font.md).
- **The glass.** A tint and a blur, set by eye for each variant. See [ADR 0014](docs/adr/0014-the-glass-is-set-by-eye.md).
- **Flat values.** Chosen to match the glass, with a lit edge. See [ADR 0009](docs/adr/0009-flat-is-the-glass-as-it-looks.md).
- **What chrome carries.** Primary text and solid fills, because only those pass everywhere. See [ADR 0010](docs/adr/0010-chrome-carries-what-passes-everywhere.md).
- **Contrast floor.** Holds on solid surfaces; the glass is set by eye. See [ADR 0011](docs/adr/0011-the-contrast-floor-holds-over-any-backdrop.md) and [ADR 0014](docs/adr/0014-the-glass-is-set-by-eye.md). Opacity-only glass has its own rows. See [ADR 0013](docs/adr/0013-opacity-only-glass-has-its-own-floor-rows.md).
- **See-through highlights.** One wash alpha per variant, applied to any color role. See [ADR 0006](docs/adr/0006-one-wash-alpha-for-highlights.md), amended by [ADR 0011](docs/adr/0011-the-contrast-floor-holds-over-any-backdrop.md).
- **Port icons.** Single-color, colored by the page, so they follow the palette rule. A brand mark where the app allows it, otherwise a glyph. See [ADR 0007](docs/adr/0007-port-icons-are-single-color.md).
