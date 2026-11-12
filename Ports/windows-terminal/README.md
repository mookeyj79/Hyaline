# Hyaline for Windows Terminal

**Tier:** 1 Full glass
**Variants:** Hyaline Dark, Hyaline Light (each with a Flat version)
**Tested with:** not yet tested on a real machine. Built from the official docs (see Sources).

| Hyaline Dark | Hyaline Light |
|---|---|
| ![Hyaline Dark](screenshots/dark.png) | ![Hyaline Light](screenshots/light.png) |

<!-- Screenshots are added by hand. Leave the paths in place. -->

The port has three parts:

- **Color schemes** color the terminal text and background. They install as a [JSON fragment](https://learn.microsoft.com/windows/terminal/json-fragment-extensions), so you copy files instead of pasting JSON.
- **Themes** color the tab row and window frame. Fragments cannot hold themes, so these are pasted into `settings.json`.
- **Profile defaults** turn on the glass and set the font for every profile.

Each variant comes in two versions:

| Name | Use it when |
|---|---|
| `Hyaline Dark`, `Hyaline Light` | You want glass: a blurred, translucent window |
| `Hyaline Dark Flat`, `Hyaline Light Flat` | You have **Transparency effects** turned off, or prefer a solid window |

## Before you start

- Windows Terminal 1.16 or later. Check it in **Settings** > **About**.
- The glass tab row needs Windows 11 build 22621 or later (Mica). The glass terminal area also works on Windows 10.
- A text editor for `settings.json`. Windows Terminal opens it in your default editor.

## Install

These steps install both variants and let Windows Terminal follow your Windows light or dark setting. To use only one variant, see [Switch between Dark and Light](#switch-between-dark-and-light) after step 14.

### Color schemes

1. Download or clone this repo.
2. Open File Explorer, click the address bar, type `%LOCALAPPDATA%\Microsoft\Windows Terminal`, and press **Enter**.
3. If there is no `Fragments` folder, create one. Open it.
4. Inside `Fragments`, create a folder named `Hyaline` and open it.
5. Copy these two files into it:
   - `Ports/windows-terminal/dist/dark/schemes-dark.json`
   - `Ports/windows-terminal/dist/light/schemes-light.json`

   The first file is now at `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\Hyaline\schemes-dark.json`.
6. Close every Windows Terminal window, then open it again. Fragments are read at startup.

### Themes

7. Press **Ctrl+,** to open **Settings**.
8. Click **Open JSON file** in the bottom-left corner. `settings.json` opens in your editor.
9. Find the line `"themes": [`. If there is none, add `"themes": [],` on a new line right after the first `{` in the file.
10. Open `Ports/windows-terminal/dist/dark/themes-dark.json`. Copy the two `{ ... }` objects between its `[` and `]`, and paste them inside the `"themes"` brackets in `settings.json`.
11. Do the same with `Ports/windows-terminal/dist/light/themes-light.json`. Put a comma between each object.
12. Find the top-level `"theme"` line (add it after `"themes"` if missing) and set it to:

    ```json
    "theme": { "dark": "Hyaline Dark", "light": "Hyaline Light" },
    ```

### Profile defaults

13. Find `"defaults"` inside `"profiles"`. Add these lines inside its braces:

    ```json
    "colorScheme": { "dark": "Hyaline Dark", "light": "Hyaline Light" },
    "opacity": 93,
    "useAcrylic": true,
    "font": { "face": "FiraCode Nerd Font Mono" }
    ```

    The `opacity` is the one in `dist/light/profile-defaults-light.json`. Windows Terminal has one opacity for both variants, so use the denser of the two. Text stays readable in both.
14. Save `settings.json`. Windows Terminal applies it right away. If it shows an error banner, a comma is missing or extra (see Troubleshooting).

If a profile in `"list"` sets its own `colorScheme`, `opacity`, `useAcrylic`, or `font`, it overrides these defaults. Remove those lines from the profile to use Hyaline.

Files to use:

- Hyaline Dark: `dist/dark/schemes-dark.json`, `dist/dark/themes-dark.json`
- Hyaline Light: `dist/light/schemes-light.json`, `dist/light/themes-light.json`

`dist/<variant>/profile-defaults-<variant>.json` shows which settings go where for a single variant. It is a reference, not a file to install.

## Set the font

Hyaline uses [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads). If it is not installed yet, follow [Font](../../README.md#font) in the main README.

Step 13 already sets it. To set it from the settings screen instead:

1. Press **Ctrl+,**, then click **Defaults** under **Profiles** in the left menu.
2. Click **Appearance**, then **Font face**.
3. Pick **FiraCode Nerd Font Mono**, then click **Save**.

Ligatures are on by default. To turn them off, add `"features": { "liga": 0, "calt": 0 }` inside the `"font"` braces.

## Check that it worked

Open a new tab. The terminal area is a frosted panel with the desktop blurred behind it, and the tab row is clearer glass. In PowerShell, run `Write-Host "error" -ForegroundColor Red`: the word shows in Hyaline red, softer than the default red.

## Switch between Dark and Light

With the install above, Windows Terminal follows Windows. Change it in Windows **Settings** > **Personalization** > **Colors** > **Choose your mode**.

To pin one variant instead:

1. Open `settings.json` (steps 7 and 8).
2. Set `"theme": "Hyaline Dark"` (or `"Hyaline Light"`).
3. In `"profiles"` > `"defaults"`, set `"colorScheme": "Hyaline Dark"` (or `"Hyaline Light"`).
4. Set `"opacity"` to the value in that variant's `profile-defaults-*.json`.
5. Save.

Keep the theme and the color scheme on the same variant.

### Use the Flat version

1. In `settings.json`, add ` Flat` to the end of every Hyaline name in `"theme"` and `"colorScheme"`, for example `"Hyaline Dark Flat"`.
2. In `"defaults"`, set `"opacity": 100` and `"useAcrylic": false`.
3. Save.

## Turn on the glass effect

The install already turns it on. If the window is still solid:

1. In Windows **Settings** > **Personalization** > **Colors**, turn on **Transparency effects**.
2. Make sure no profile in `"list"` overrides `opacity` or `useAcrylic`.
3. For glass on windows in the background too, turn on the global **Enable unfocused acrylic** setting in Windows Terminal.

Without Mica (Windows 10, or Windows 11 before build 22621), the tab row cannot show the desktop. Set `"theme"` to the Flat version and keep the glass color scheme for the terminal area.

## Uninstall

1. Delete the folder `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\Hyaline`.
2. Open `settings.json` (steps 7 and 8).
3. Remove the four Hyaline objects from `"themes"`.
4. Set `"theme": "system"`.
5. Remove the `colorScheme`, `opacity`, `useAcrylic`, and `font` lines you added to `"defaults"`.
6. Save, then restart Windows Terminal.

## Troubleshooting

- **The Hyaline schemes are missing from the Color scheme list**: check the folder in step 5, and restart every Windows Terminal window. Copy the files from the repo again if you edited them; Windows Terminal ignores a fragment saved as UTF-16.
- **Error banner after saving `settings.json`**: usually a missing comma between pasted theme objects, or a trailing comma after the last one.
- **The window is solid**: see [Turn on the glass effect](#turn-on-the-glass-effect).
- **The tab row is solid but the terminal is glass**: your Windows build has no Mica. Use the Flat theme.
- **Light looks bright white instead of frosted**: transparency is off. Turn it on, or use the Flat version.
- **Some colors look shifted**: set `"adjustIndistinguishableColors": "never"` in `"defaults"`. That setting changes text colors it thinks are too close to the background.

---

## Reference

### Role mapping

Color scheme:

| App setting | Role |
|---|---|
| `background` | `panel` (glass) or `panel_flat` (Flat) |
| `foreground` | `text` |
| `cursorColor` | `accent` |
| `selectionBackground` | `accent` |
| `black` | Dark `raised_flat`, Light `text` |
| `red`, `brightRed` | `red` |
| `green`, `brightGreen` | `green` |
| `yellow`, `brightYellow` | `yellow` |
| `blue`, `brightBlue` | `blue` |
| `purple`, `brightPurple` | `magenta` |
| `cyan`, `brightCyan` | `cyan` |
| `white` | Dark `text_dim`, Light `line` |
| `brightBlack` | `text_muted` |
| `brightWhite` | Dark `text`, Light `raised_flat` |

Profile:

| App setting | Value |
|---|---|
| `opacity` | `panel` alpha, as a percent |
| `useAcrylic` | `true` (glass), `false` (Flat) |
| `font.face` | FiraCode Nerd Font Mono |

Theme:

| App setting | Role |
|---|---|
| `window.applicationTheme` | the variant's mode, `dark` or `light` |
| `window.useMica` | `true` (glass), `false` (Flat) |
| `window.frame` | `accent` |
| `window.unfocusedFrame` | `line` |
| `tabRow.background`, `tabRow.unfocusedBackground` | `chrome` with its alpha (glass), `chrome_flat` (Flat) |
| `tab.background` (active tab) | `panel_flat` |
| `tab.unfocusedBackground` | not set, so inactive tabs show the tab row |

The glass scheme's `background` is the panel tint and `opacity` is the panel alpha, so the terminal area is the same `panel` glass as other Tier 1 ports. Windows Terminal always draws the active tab solid, so it uses `panel_flat`: the color the pane appears as over a neutral backdrop.

### Known gaps

- **One opacity for both variants.** `opacity` is a profile setting, not part of the scheme. When following Windows, use Hyaline Light's denser value, so Hyaline Dark is a little more solid than on other glass ports.
- **Tab and menu text color** cannot be set. It comes from `applicationTheme`: light text in dark mode, dark text in light mode.
- **Selected text** keeps its own color on the `accent` selection. Windows Terminal has no selection text color setting. Check that selected text is readable when taking screenshots, especially in Light.
- **Window frame colors** (`frame`, `unfocusedFrame`) only work in Windows Terminal Preview on Windows 11, per the docs. Other versions ignore them.
- **Mica** needs Windows 11 build 22621 or later. Without it the glass tab row is not see-through.
- **Bright ANSI colors** match their normal colors on purpose.
- **Scrollbar, command palette, and settings screen** follow `applicationTheme`, not Hyaline colors.
- **Not tested on a real machine yet.** Screenshots and a tested version are still to come.

### Sources and credits

- [Color schemes](https://learn.microsoft.com/windows/terminal/customize-settings/color-schemes): scheme keys
- [Themes](https://learn.microsoft.com/windows/terminal/customize-settings/themes): `tabRow`, `tab`, `window`, Mica, `#rrggbbaa` colors, `theme` as a light/dark pair
- [Appearance profile settings](https://learn.microsoft.com/windows/terminal/customize-settings/profile-appearance): `colorScheme` as a light/dark pair, `opacity`, `useAcrylic`, `font`, `adjustIndistinguishableColors`
- [JSON fragment extensions](https://learn.microsoft.com/windows/terminal/json-fragment-extensions): fragment folder and rules
- [Windows Terminal Preview 1.16 release](https://devblogs.microsoft.com/commandline/windows-terminal-preview-1-16-release/): themes added in 1.16
- Ports studied: [Catppuccin for Windows Terminal](https://github.com/catppuccin/windows-terminal) and [Rosé Pine for Windows Terminal](https://github.com/rose-pine/windows-terminal), both MIT. Method only: one scheme and one theme per variant, and leaving `tab.unfocusedBackground` unset. No files or colors reused.
