# Cinnamon: role mapping

For maintainers. The install guide is [README.md](README.md).

## Role mapping

Surfaces:

| Part of Cinnamon | Role |
|---|---|
| Panel bar (top, bottom, left, right) | `chrome_flat`, `text` only, `edge_flat` on the top inside, `line` border on the side facing the desktop |
| Hover on the panel bar (applets, window list, launchers) | `raised_flat` |
| Menus, applet popups, calendar, notifications, dialogs, OSDs, Alt+Tab, tooltips, window previews | `panel_flat` with a `line` border |
| Buttons, entries, submenus | `raised_flat` with a `line` border and `edge_flat` on the top inside |
| Menu sidebar, keys of the on-screen keyboard, badges, dialog lists | `raised_flat` with a `line` border |
| Lock screen cards, desklets, sound player overlay | `panel` (translucent) with a `line` border |
| Lock screen and workspace overview background | `backdrop` |
| Dimmed screen behind dialogs and Alt+Tab previews | `chrome` (translucent) |
| Window snap preview | `raised_flat` with an `accent` border |
| Separators, borders, scroll bars, slider tracks | `line` |

States:

| State | Role |
|---|---|
| Hover and keyboard selection in menus, lists, calendar | `accent` wash (`accent\|washflat`) |
| Pressed, checked, default button, today, current workspace, selected window caption | `accent` fill, `on_accent` text |
| Focused window in the window list, active workspace frame, focus ring | `accent` border |
| Shut down button, destructive dialog button, close button in the overview | `red` fill, `on_accent` text |
| Drag zones on the panel bar in edit mode | `accent` fill, `on_accent` text |
| Panel or applet picked out from the panel settings | `red` fill, `on_accent` text |
| Spot for a new panel | `accent` border, `accent` fill when the pointer is over it |
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
- **Raised is solid.** Cinnamon has opacity but no blur, so raised surfaces use `raised_flat` everywhere, including hover on the panel bar and the snap preview (ADR 0008).
- **No washes on the panel bar.** It is chrome, so drag and edit highlights are solid `accent` or `red` fills with `on_accent` (ADR 0010). St does not inherit a parent's color into an applet that sets its own, so the highlight rules also set `on_accent` on `.applet-box` and window list items inside the highlighted area.
- **The edge (ADR 0009).** Every edged surface here is solid, so it uses `edge_flat`, not the translucent `edge`. St draws only one border color per element (`st-theme-node-drawing.c`: "TODO - support non-uniform border colors"; the color of the top side is used for all four), so the edge cannot be a different-colored top border next to the `line` border. It is drawn as an inset box shadow, `inset 0 1px`, which St paints inside the border (`paint_inset_box_shadow_to_cairo_context`). St allows one box shadow per element (`st_theme_node_lookup_shadow` keeps a single shadow), so the panel bar's `line` moved from a box shadow to a one-sided border. That border takes 1 px from the bar's content area.
- **Where the edge is not drawn.** On a left or right panel bar the edge still runs along the top inside, across the width of the bar. Pressed, checked, and disabled buttons and entries drop it, since they are solid accent fills or sit at `panel_flat`. The menu sidebar, on-screen keyboard keys, badges, and dialog lists have no edge, to keep their many states simple. In Light, `edge_flat` is white on white `raised_flat`, so the `line` border carries the lift there, as ADR 0009 says.
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
- How St draws borders and box shadows (one border color per element, one inset or outer box shadow): [`src/st/st-theme-node-drawing.c`](https://github.com/linuxmint/cinnamon/blob/6.8.0/src/st/st-theme-node-drawing.c) and [`src/st/st-theme-node.c`](https://github.com/linuxmint/cinnamon/blob/6.8.0/src/st/st-theme-node.c) at tag 6.8.0.
- Studied: the `cinnamon/` folder of [Catppuccin GTK Theme by Fausto-Korpsvart](https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme) (GPL-3.0, archived), for which parts of Cinnamon a full theme covers and how it ships SVG assets next to the stylesheet. No files, colors, or declarations were reused.
