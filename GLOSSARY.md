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
Whatever sits behind the app: a wallpaper, or the `backdrop` role where there is none.
_Avoid_: Background (ambiguous with panel)

**Wallpaper**:
A found image shipped as a backdrop, marked with the variant it suits.
_Avoid_: Background image

**Wallpaper pair**:
Two wallpapers of the same kind of subject in a matching style, one for Dark and one for Light.

**Chrome**:
The frame around content, such as title bars, tabs, toolbars, and sidebars that list only names. It is clearer glass than the panel and carries only primary text and solid fills. An area that shows dim, muted or colored text is content, wherever it sits.
_Avoid_: Frame, toolbar color

**Panel**:
The main surface of an app, where content lives. Smoke-tinted in Dark, frost-tinted in Light.
_Avoid_: Background, window

**Raised**:
A surface lifted above a panel: title bars, tabs, cards, inputs.

**Edge**:
A lit hairline where light catches the glass: on the top of chrome and raised surfaces, and around the window. It carries no meaning.
_Avoid_: Border, outline

**Flat fallback**:
The solid color of a surface, chosen to look like its glass. Used wherever the app cannot do translucency.
_Avoid_: Opaque version, lite version

**Opacity-only glass**:
Translucent surfaces in an app that offers a tint and a single opacity, with no clamp. Blur, if the app has any, is not counted.
_Avoid_: Dense tint, transparency

## Color roles

**Accent**:
The role that means "you are here": focus, selection, cursor, links. One fixed blue, shared in hue with Blue.
_Avoid_: Highlight, primary color

**Contrast floor**:
The lowest contrast a role may have on a surface, over any backdrop. Solid surfaces are measured as drawn, translucent ones over pure black and pure white. Opacity-only glass has its own, lower rows.

**Wash**:
A color role at the variant's wash alpha, laid over a panel to mark something without hiding the text on it: selections, diff lines, find matches.
Only accent and the seven colors (red to orange) can be a wash. Those are the ones checked for contrast on a wash, so the build refuses `|wash` and `|washflat` on any other role.
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
Tier 1. Complete palette on translucent surfaces that stay readable over any backdrop, with or without blur.

**Flat**:
Tier 2. Complete palette on solid surfaces.

**Minimal**:
Tier 3. The app only allows background, accent and status colors.
_Avoid_: Accent tier
