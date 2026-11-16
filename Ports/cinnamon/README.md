# Hyaline for Cinnamon

**Tier:** 2 Flat
**Variants:** Hyaline Dark, Hyaline Light
**Tested with:** Not tested yet

The port is a Cinnamon **Desktop** theme: the panel bar, start menu, applet menus, calendar, notifications, on-screen displays, Alt+Tab, dialogs, the lock screen, workspace overview, and desklets. It does not change app windows, title bars, icons, or the mouse pointer. Those are set separately in Cinnamon (see [Known limits](#known-limits)).

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

The panel bar is a soft gray (Dark) or pale frost (Light), with a thin lit line along its top. Open the start menu: it is a solid smoke or frost panel with a thin border, the item under the pointer has a faint blue tint, and today's date in the calendar applet sits in a solid blue circle.

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

## Troubleshooting

- **Hyaline is not in the Desktop list**: the folder is one level too deep or too shallow. The file must be at `~/.themes/Hyaline Dark/cinnamon/cinnamon.css`. Close and reopen **Themes** after fixing it.
- **The desktop looks like the Cinnamon default after picking Hyaline**: Cinnamon could not read the theme and fell back to its default. Press **Alt+F2**, type `lg`, press **Enter**, and open the **Log** tab. Look for "There was some problem parsing the theme". Copy the folders again from `dist/`; do not edit them by hand.
- **Changes do not show after updating the files**: pick another Desktop theme and then Hyaline again, or restart Cinnamon with **Ctrl+Alt+Esc**.
- **App windows and title bars did not change**: expected. This port themes the desktop only. Windows use the **Applications** and window border themes.
- **An applet from Cinnamon Spices looks off**: some third-party applets bring their own styles or use class names that Cinnamon's own theme does not define. Hyaline covers the classes that ship with Cinnamon.

## Known limits

- **No blur.** Cinnamon can make the lock screen cards and desklets see-through, but it cannot blur what is behind them. The panel bar and menus are solid.
- **Desktop only.** App windows, title bars, icons, and the mouse pointer are not changed. Cinnamon sets them with the **Applications**, **Icons**, and **Mouse Pointer** themes.
- **No preview picture** in the theme chooser. Hyaline shows a generic picture next to **Desktop**.
- **No shadows.** Menus and popups have a thin border instead of a drop shadow.
- **Third-party applets and desklets** that bring their own styles may look out of place.
- **No automatic Dark and Light switching.** Cinnamon has no setting to change the Desktop theme with the light or dark mode.

## Sources

- [Cinnamon Spices: Themes](https://cinnamon-spices.linuxmint.com/themes): installing themes in `~/.themes`
- [Cinnamon theme manager](https://github.com/linuxmint/cinnamon/blob/master/js/ui/themeManager.js): where Cinnamon looks for Desktop themes
- [Cinnamon Themes settings page](https://github.com/linuxmint/cinnamon/blob/master/files/usr/share/cinnamon/cinnamon-settings/modules/cs_themes.py): Advanced settings and the Desktop chooser
