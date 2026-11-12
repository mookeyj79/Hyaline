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
| **Backdrop** | Whatever is behind the app: wallpaper, or a soft neutral where there is none. Always light and airy, in both variants. |
| **Chrome** | The frame around content: title bars, tabs, sidebars, toolbars. The clearest glass. Carries primary text and solid accent fills only. |
| **Panel** | The main surface, where content lives. Smoke-tinted in Dark, frost-tinted in Light. Translucent where possible, but dense enough that every role stays readable over a wallpaper. |
| **Raised** | A slightly lifted surface on top of a panel: title bars, tabs, cards, inputs. |
| **Line** | Borders and dividers. Thin, low contrast, never decorative. |
| **Text** | Three strengths: primary (content), dim (supporting), muted (comments, metadata). |

### The flat fallback

Many apps cannot do translucency. For those, the palette defines a **flat** value for each surface: the solid color the panel would appear as over a neutral backdrop.

Flat is not a lesser version. It is the same theme with the window closed.

One exception: Hyaline Light's `panel_flat` is pinned to the frost tint instead of being derived from the panel's alpha, so flat Light ports keep their frost. See [ADR 0004](docs/adr/0004-chrome-and-content-glass-split.md).

### Chrome and content

Glass that is clear enough to see through is not safe behind colored text. So the window is split:

- **Chrome** is clear glass. It holds primary text and solid accent fills (a selected tab, an active item) with `on_accent`. No dim, muted, or colored text.
- **Panel** holds content: code, output, documents. Every role passes there.

If an app cannot tell chrome from content, use `panel` everywhere.

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
| **1** | Full glass | Complete palette, translucency, and blur |
| **2** | Flat | Complete palette using flat fallbacks. No blur. |
| **3** | Minimal | The app only allows limited theming: background, accent, and status colors |

A Tier 3 port is a win, not a compromise. The tier exists so "close enough" is a defined grade and not an argument to have every time.

## Contrast floor

Measured against the flat fallback, since that is the worst case.

- **Primary and dim text**: at least 4.5:1 against the panel.
- **Muted text, borders that carry meaning, icons**: at least 3:1.
- **Role colors used as text**: at least 4.5:1 in both variants.
- **On a wash** (a color role at the variant's wash alpha, used for selections and diff lines): primary and dim text at least 4.5:1, muted text and role colors at least 3:1. See [ADR 0006](docs/adr/0006-one-wash-alpha-for-highlights.md).

The light variant is where this bites. Yellow and cyan get darkened until they pass. Pastels on frost are not allowed, no matter how nice they look in a swatch.

## Hard no's

- **No hex values outside the palette.** Ports reference roles only. Wallpapers are the one exception: they are image assets, not colors (ADR 0003).
- **No inventing colors in a port.** If a port truly needs a new one, it goes into the palette and becomes available to every port.
- **No single-variant ports.** Ship Dark and Light together. If an app only supports one mode, say so in the README.
- **No pure black backgrounds and no pure white text.** Smoke is not black, and nothing here should glow.
- **No decoration.** No text glow, no gradients on text, no shadows other than the single soft panel shadow.
- **No blur behind dense text unless the tint is strong enough to pass the contrast floor.**
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
- A **README** that is a step-by-step install guide. Someone who has never themed the app should be able to follow it start to finish. It also states the tier and known gaps.
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
- **Backdrop.** The repo will ship wallpapers: found images with a license that allows redistribution and a recorded credit. They are the one exception to the palette rule. See [ADR 0003](docs/adr/0003-wallpapers-are-found-images.md) and [issue #1](https://github.com/mookeyj79/Hyaline/issues/1).
- **Font.** FiraCode Nerd Font, set in every app that allows it. See [ADR 0005](docs/adr/0005-recommended-font.md).
- **How clear the glass is.** Chrome is clear, content is dense. See [ADR 0004](docs/adr/0004-chrome-and-content-glass-split.md).
- **See-through highlights.** One wash alpha per variant, applied to any color role. See [ADR 0006](docs/adr/0006-one-wash-alpha-for-highlights.md).
