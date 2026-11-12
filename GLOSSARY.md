# Hyaline

One color theme, ported to many apps, so every tool on the machine looks like it belongs together.

## Theme

**Theme**:
Hyaline as a whole: one set of roles shipped as two variants.
_Avoid_: Skin, scheme

**Variant**:
One of the two looks of the theme: Hyaline Dark (smoke) or Hyaline Light (frost). They always ship together.
_Avoid_: Flavor, mode (mode is only the `dark`/`light` label)

**Role**:
A named job a color does, such as `panel`, `text` or `red`. Ports pick roles. The palette decides the color.
_Avoid_: Color, swatch, token

**Palette**:
The single source of every role's value, for both variants.

## Surfaces

**Backdrop**:
Whatever sits behind the app: a wallpaper, or the `backdrop` role where there is none. Always light and airy.
_Avoid_: Background (ambiguous with panel)

**Wallpaper**:
A found image shipped as a backdrop. Light, low detail and low saturation, and shared by both variants.
_Avoid_: Background image

**Chrome**:
The frame around content: title bars, tabs, sidebars, toolbars. The clearest glass, so it carries only primary text and solid accent fills.
_Avoid_: Frame, toolbar color

**Panel**:
The main surface of an app, where content lives. Smoke-tinted in Dark, frost-tinted in Light.
_Avoid_: Background, window

**Raised**:
A surface lifted above a panel: title bars, tabs, cards, inputs.

**Flat fallback**:
The solid color a translucent surface appears as over a neutral backdrop. Used wherever the app cannot blur.
_Avoid_: Opaque version, lite version

## Color roles

**Accent**:
The role that means "you are here": focus, selection, cursor, links. One fixed blue, shared in hue with Blue.
_Avoid_: Highlight, primary color

**Wash**:
A color role at the variant's wash alpha, laid over a panel to mark something without hiding the text on it: selections, diff lines, find matches.
_Avoid_: Tint, highlight color

## Ports

**Port**:
Hyaline applied to one app, with its own folder, templates, generated output and install guide.
_Avoid_: Theme (for a single app), plugin

**Port icon**:
The single-color mark on a port's card on the ports page, colored by the page. Either a brand mark (the app's own logo shape) or a glyph (a symbol for what the app is). The monogram stands in when there is none.
_Avoid_: Logo, favicon

**Tier**:
The grade a port declares for how much of the theme the app allows: Full glass, Flat or Minimal.

**Full glass**:
Tier 1. Complete palette, translucency and blur.

**Flat**:
Tier 2. Complete palette using flat fallbacks, no blur.

**Minimal**:
Tier 3. The app only allows background, accent and status colors.
_Avoid_: Accent tier
