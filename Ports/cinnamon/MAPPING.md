# Cinnamon: role mapping

For maintainers. The install guide is [README.md](README.md).

## Role mapping

Surfaces:

| Part of Cinnamon | Role |
|---|---|
| Panel bar (top, bottom, left, right) | `chrome_flat`, `text` only, `line` edge |
| Hover on the panel bar (applets, window list, launchers) | `raised` (translucent, over `chrome_flat`) |
| Menus, applet popups, calendar, notifications, dialogs, OSDs, Alt+Tab, tooltips, window previews | `panel_flat` with a `line` border |
| Buttons, entries, submenus, menu sidebar, keys of the on-screen keyboard | `raised_flat` with a `line` border |
| Lock screen cards, desklets, sound player overlay | `panel` (translucent) with a `line` border |
| Lock screen and workspace overview background | `backdrop` |
| Dimmed screen behind dialogs and Alt+Tab previews | `chrome` (translucent) |
| Window snap preview | `raised` (translucent) with an `accent` border |
| Separators, borders, scroll bars, slider tracks | `line` |

States:

| State | Role |
|---|---|
| Hover and keyboard selection in menus, lists, calendar | `accent` wash (`accent\|washflat`) |
| Pressed, checked, default button, today, current workspace, selected window caption | `accent` fill, `on_accent` text |
| Focused window in the window list, active workspace frame, focus ring | `accent` border |
| Shut down button, destructive dialog button, close button in the overview | `red` fill, `on_accent` text |
| Window asks for attention | `yellow` bar |
| Progress in the window list | `blue` |
| Unread notification count | `accent` fill, `on_accent` text |
| Disabled items and buttons | `text_muted` |
| Volume over 100 percent | `yellow` |

Text:

| Text | Role |
|---|---|
| Labels, titles, menu items | `text` |
| Descriptions, secondary labels, weekend days, day headings | `text_dim` |
| Hints, days from other months, past events, placeholders | `text_muted` |
| Links, all-day events | `accent` |
| Errors, critical battery, imminent event | `red` |
| Caps Lock warning, event starting soon, end-session warning | `yellow` |
| Event happening now | `green` |

Symbolic icon states (`warning-color`, `error-color`, `success-color`) use `yellow`, `red`, and `green`.

Images in `cinnamon/assets/` (check boxes, radio buttons, switches, calendar arrows, workspace add and close buttons, the trash area, and the hot corner ripple) are drawn for this port and colored from the same roles as the stylesheet.

## Gaps and trade-offs

- **No blur.** Cinnamon can draw translucent surfaces but cannot blur what is behind them, so menus and the panel bar use the flat colors. The lock screen and desklets keep the translucent `panel`, which is dense enough to read over a wallpaper without blur. Tier 2.
- **Desktop only.** App windows, title bars, icons, and the mouse pointer are separate theme types in Cinnamon. GTK apps are covered by the planned GTK port (`gtk` in `Ports/ports.json`).
- **No preview picture** in the theme chooser. Cinnamon looks for `cinnamon/thumbnail.png`, which would be a fixed image outside the palette.
- **Hover on the Light panel bar is faint.** The `raised` glass barely lightens Light `chrome_flat`. Hover in menus uses the accent wash and is clearly visible in both variants.
- **No shadows.** Popups use a `line` border instead of a drop shadow, like the other Hyaline ports.
- **Third-party applets and desklets** that add their own class names are not styled.
- **No automatic Dark and Light switching.** Cinnamon has no setting to change the Desktop theme with the light or dark mode.
- **Not tested on a real machine yet.** Built against the Cinnamon 6.8 theme selectors.

## Research

- Cinnamon's default theme, the reference for every class name this port styles: [linuxmint/cinnamon `data/theme/cinnamon-sass`](https://github.com/linuxmint/cinnamon/tree/master/data/theme/cinnamon-sass) at tag 6.8.0. No declarations were copied; the stylesheet is written for this port.
- How Cinnamon finds and loads a Desktop theme (`~/.local/share/themes`, `~/.themes`, then system folders, each with `cinnamon/cinnamon.css`): [`js/ui/themeManager.js`](https://github.com/linuxmint/cinnamon/blob/master/js/ui/themeManager.js).
- Why the theme must style everything: Cinnamon only falls back to its default stylesheet for a few core widgets when a theme has no rule for them ([`src/st/st-theme.c`](https://github.com/linuxmint/cinnamon/blob/master/src/st/st-theme.c)).
- The Themes settings page (Advanced settings, the Desktop chooser, the Dark mode option, and `thumbnail.png`): [`cs_themes.py`](https://github.com/linuxmint/cinnamon/blob/master/files/usr/share/cinnamon/cinnamon-settings/modules/cs_themes.py).
- Installing themes in `~/.themes`: [Cinnamon Spices, Themes](https://cinnamon-spices.linuxmint.com/themes).
- Studied: the `cinnamon/` folder of [Catppuccin GTK Theme by Fausto-Korpsvart](https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme) (GPL-3.0, archived), for which parts of Cinnamon a full theme covers and how it ships SVG assets next to the stylesheet. No files, colors, or declarations were reused.
