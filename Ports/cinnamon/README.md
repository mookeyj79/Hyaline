# Hyaline for Cinnamon

**Tier:** 2 Flat
**Variants:** Hyaline Dark, Hyaline Light
**Tested with:** not yet tested on a real machine. Built against the Cinnamon 6.8 theme selectors (see Sources).

| Hyaline Dark | Hyaline Light |
|---|---|
| ![Hyaline Dark](screenshots/dark.png) | ![Hyaline Light](screenshots/light.png) |

<!-- Screenshots are added by hand. Leave the paths in place. -->

The port is a Cinnamon **Desktop** theme: the panel bar, start menu, applet menus, calendar, notifications, on-screen displays, Alt+Tab, dialogs, the lock screen, workspace overview, and desklets. It does not change app windows, title bars, icons, or the mouse pointer. Those are set separately in Cinnamon (see Known gaps).

## Before you start

- Cinnamon 6.x, for example Linux Mint 22. Older versions use some different class names and may look partly unstyled.
- FiraCode Nerd Font, for the intended look (see [Set the font](#set-the-font)). Without it, Cinnamon falls back to a sans-serif font.

## Install

1. Download or clone this repo.
2. Open your file manager (Nemo on Linux Mint) and go to your home folder.
3. Press **Ctrl+H** to show hidden folders.
4. Open the `.themes` folder. If it does not exist, create a folder named `.themes` and open it.
5. Copy the folder `Ports/cinnamon/dist/dark/Hyaline Dark` into `.themes`. You should now have `~/.themes/Hyaline Dark/cinnamon/cinnamon.css`.
6. Copy the folder `Ports/cinnamon/dist/light/Hyaline Light` into `.themes` the same way.
7. Open the menu and start **System Settings**, then click **Themes**.
8. If the page shows **Mixed**, **Dark**, and **Light** pictures, click **Advanced settings...** at the bottom. You now see a list with **Mouse Pointer**, **Applications**, **Icons**, and **Desktop**.
9. Click the picture next to **Desktop** and choose **Hyaline Dark** or **Hyaline Light**. Hyaline has no preview picture, so it shows a generic one.

The panel and menus change right away. No log out is needed.

From a terminal, steps 7 to 9 are one command:

```
gsettings set org.cinnamon.theme name 'Hyaline Dark'
```

Files to use:

- Hyaline Dark: `dist/dark/Hyaline Dark/` (the whole folder)
- Hyaline Light: `dist/light/Hyaline Light/` (the whole folder)

`~/.local/share/themes` works as well as `~/.themes`. To install for every user on the machine, copy the folders to `/usr/share/themes` instead (needs admin rights).

## Set the font

Hyaline uses [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads). If it is not installed yet, follow [Font](../../README.md#font) in the main README.

In Cinnamon the Desktop theme sets the font, so there is nothing to change: both Hyaline themes use **FiraCode Nerd Font Mono** for the panel, menus, and popups. This affects only the desktop. App windows keep the font set in **System Settings > Font Selection**. After installing the font, pick the theme again (step 9) or restart Cinnamon (**Ctrl+Alt+Esc**).

To keep Hyaline's colors with another desktop font:

1. Open `~/.themes/Hyaline Dark/cinnamon/cinnamon.css` in a text editor.
2. Find the `font-family` line near the top, under `stage`.
3. Replace `"FiraCode Nerd Font Mono"` with the font you want, for example `"Ubuntu"`.
4. Save, then pick the theme again in **Themes > Desktop**.
5. Repeat for `Hyaline Light` if you use it.

Font size comes from **System Settings > Font Selection > Default font**.

## Check that it worked

The panel bar is a soft gray (Dark) or pale frost (Light). Open the start menu: it is a solid smoke or frost panel with a thin border, the item under the pointer has a faint blue tint, and today's date in the calendar applet sits in a solid blue circle.

## Switch between Dark and Light

1. Open **System Settings > Themes** (click **Advanced settings...** if you see the Mixed, Dark, and Light pictures).
2. Click the picture next to **Desktop** and pick the other Hyaline theme.

Or run `gsettings set org.cinnamon.theme name 'Hyaline Light'` (or `'Hyaline Dark'`).

Cinnamon cannot switch the Desktop theme with the time of day or the light and dark setting. The **Dark mode** option under **Themes > Settings** only affects apps that support it.

## Uninstall

1. Open **System Settings > Themes > Advanced settings...**.
2. Click the picture next to **Desktop** and choose your previous theme, such as **Mint-Y-Dark**, or **cinnamon** for the Cinnamon default.
3. Open `~/.themes` in your file manager (**Ctrl+H** shows it).
4. Delete the `Hyaline Dark` and `Hyaline Light` folders.

If either folder also holds other Hyaline ports (such as a GTK theme), delete only the `cinnamon` folder inside it.

## Troubleshooting

- **Hyaline is not in the Desktop list**: the folder is one level too deep or too shallow. The file must be at `~/.themes/Hyaline Dark/cinnamon/cinnamon.css`. Close and reopen **Themes** after fixing it.
- **The desktop looks like the Cinnamon default after picking Hyaline**: Cinnamon could not read the theme and fell back to its default. Press **Alt+F2**, type `lg`, press **Enter**, and open the **Log** tab. Look for "There was some problem parsing the theme". Copy the folders again from `dist/`; do not edit them by hand.
- **Changes do not show after updating the files**: pick another Desktop theme and then Hyaline again, or restart Cinnamon with **Ctrl+Alt+Esc**.
- **App windows and title bars did not change**: expected. This port themes the desktop only. Windows use the **Applications** and window border themes.
- **An applet from Cinnamon Spices looks off**: some third-party applets bring their own styles or use class names that Cinnamon's own theme does not define. Hyaline covers the classes that ship with Cinnamon.

---

## Reference

### Role mapping

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

Images in `cinnamon/assets/` (check boxes, radio buttons, switches, calendar arrows, workspace add and close buttons, the trash area, and the hot corner ripple) are drawn for this port and colored from the same roles.

### Known gaps

- **No blur.** Cinnamon can draw translucent surfaces but cannot blur what is behind them, so menus and the panel bar use the flat colors. The lock screen and desklets keep the translucent `panel`, which is dense enough to read over a wallpaper without blur.
- **Desktop only.** App windows, title bars, icons, and the mouse pointer are separate theme types in Cinnamon. GTK apps are covered by the planned GTK port.
- **No preview picture** in the theme chooser. Cinnamon looks for `cinnamon/thumbnail.png`, which would be a fixed image outside the palette.
- **Hover on the Light panel bar is faint.** The `raised` glass barely lightens Light `chrome_flat`. Hover in menus uses the accent wash and is clearly visible in both variants.
- **No shadows.** Popups use a `line` border instead of a drop shadow, like the other Hyaline ports.
- **Third-party applets and desklets** that add their own class names are not styled.
- **No automatic Dark and Light switching.** Cinnamon has no setting to change the Desktop theme with the light or dark mode.

### Sources and credits

- Cinnamon's default theme, the reference for every class name this port styles: [linuxmint/cinnamon `data/theme/cinnamon-sass`](https://github.com/linuxmint/cinnamon/tree/master/data/theme/cinnamon-sass) at tag 6.8.0. No declarations were copied; the stylesheet is written for this port.
- How Cinnamon finds and loads a Desktop theme (`~/.local/share/themes`, `~/.themes`, then system folders, each with `cinnamon/cinnamon.css`): [`js/ui/themeManager.js`](https://github.com/linuxmint/cinnamon/blob/master/js/ui/themeManager.js).
- Why the theme must style everything: Cinnamon only falls back to its default stylesheet for a few core widgets when a theme has no rule for them ([`src/st/st-theme.c`](https://github.com/linuxmint/cinnamon/blob/master/src/st/st-theme.c)).
- The Themes settings page (Advanced settings, the Desktop chooser, the Dark mode option, and `thumbnail.png`): [`cs_themes.py`](https://github.com/linuxmint/cinnamon/blob/master/files/usr/share/cinnamon/cinnamon-settings/modules/cs_themes.py).
- Installing themes in `~/.themes`: [Cinnamon Spices, Themes](https://cinnamon-spices.linuxmint.com/themes).
- Studied: the `cinnamon/` folder of [Catppuccin GTK Theme by Fausto-Korpsvart](https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme) (GPL-3.0, archived), for which parts of Cinnamon a full theme covers and how it ships SVG assets next to the stylesheet. No files, colors, or declarations were reused.
