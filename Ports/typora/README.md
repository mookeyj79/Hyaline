# Hyaline for Typora

**Tier:** 2 Flat\
**Variants:** Hyaline Dark, Hyaline Light\
**Tested with:** Not tested yet

The port is two Typora themes, one CSS file per variant. They show up in Typora's **Themes** menu as **Hyaline Dark** and **Hyaline Light**. Typora cannot make its window see-through, so the themes use solid colors.

## Before you start

- Typora 0.9.98 or later. Picking separate themes for light and dark mode arrived in 0.9.98. Any Typora 1.x works.
- FiraCode Nerd Font, for the intended look (see [Set the font](#set-the-font)). Without it, Typora falls back to Consolas or Menlo.

## Install

1. Download or clone this repo.
2. Open Typora.
3. Open the preferences: **File > Preferences** on Windows and Linux, **Typora > Settings** (or **Preferences**) on macOS.
4. Go to **Appearance** and click **Open Theme Folder**. A file window opens on Typora's theme folder. It is usually:

   | OS | Theme folder |
   |---|---|
   | Windows | `%APPDATA%\Typora\themes` |
   | macOS | `~/Library/Application Support/abnerworks.Typora/themes` |
   | Linux | `~/.config/Typora/themes` |

5. Copy `Ports/typora/dist/dark/hyaline-dark.css` into that folder.
6. Copy `Ports/typora/dist/light/hyaline-light.css` into the same folder. Keep both file names as they are: Typora builds the menu name from the file name.
7. Quit Typora completely and open it again.
8. Open the **Themes** menu in the menu bar and choose **Hyaline Dark** or **Hyaline Light**.

Files to use:

- Hyaline Dark: `dist/dark/hyaline-dark.css`
- Hyaline Light: `dist/light/hyaline-light.css`

## Set the font

Hyaline uses [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads). If it is not installed yet, follow [Font](../../README.md#font) in the main README.

In Typora the theme sets the font, so there is nothing to change: both Hyaline themes already use **FiraCode Nerd Font Mono** for prose, code blocks, inline code, and source code mode. Restart Typora after installing the font.

To keep Hyaline's colors but write prose in another font:

1. Open the theme folder (**Appearance > Open Theme Folder**).
2. Create a file named `base.user.css` there, if it does not exist.
3. Add this line, with the font you want: `body { font-family: "Segoe UI", sans-serif; }`
4. Restart Typora. Code keeps FiraCode; prose uses your font.

Font size is set in Typora itself: **Appearance > Font Size** in the preferences.

## Check that it worked

Open any Markdown file. The writing area is smoke gray (Dark) or frost white (Light), the sidebar is a slightly different shade with a blue bar on the open file, and inline `code` is orange with a thin border.

## Switch between Dark and Light

To switch by hand, open the **Themes** menu and pick the other Hyaline theme.

On Windows and macOS, Typora can follow the OS light or dark setting:

1. Open the preferences and go to **Appearance**.
2. In the theme settings, set the theme for light mode to **Hyaline Light** and the theme for dark mode to **Hyaline Dark**. The exact labels vary between Typora versions.
3. Change the OS mode (Windows: **Settings > Personalization > Colors > Choose your mode**; macOS: **System Settings > Appearance**). Typora switches theme with it.

Linux has no OS mode for Typora to follow; switch with the **Themes** menu.

## Uninstall

1. Open the **Themes** menu and pick another theme, such as **Github**.
2. Open the theme folder (**Appearance > Open Theme Folder**).
3. Delete `hyaline-dark.css` and `hyaline-light.css`.
4. If you created `base.user.css` only for Hyaline, delete it too.
5. Restart Typora. The Hyaline entries are gone from the **Themes** menu.

## Troubleshooting

- **Hyaline is not in the Themes menu**: Typora reads the folder at startup. Quit it completely (on Windows, check the tray) and reopen it. Also check that the files sit directly in `themes`, not in a subfolder.
- **The menu shows an odd name**: the file was renamed. Use the original names, `hyaline-dark.css` and `hyaline-light.css`.
- **Text is in Consolas or Menlo, not Fira Code**: FiraCode Nerd Font is not installed, or Typora was open while you installed it. Install it and restart Typora.
- **Typora did not switch with the OS**: check the light and dark mode themes in **Appearance**. This works on Windows and macOS only.
- **A diagram keeps its own colors**: colors set inside the diagram code (Mermaid `style` or `classDef`) win over the theme. That is expected.

## Known limits

- **No glass.** Typora's window is solid. A theme cannot make it see-through or blurred.
- **Code blocks and inline code sit on the page color.** They get a thin border instead of a lighter background, so colored code stays easy to read.
- **Some of Typora's own windows keep their look.** Parts of the preferences window, the export dialog, and a few icons only partly follow the theme.
- **A Typora update can leave a part unstyled.** Typora says its theme variables may change in future versions. If something looks off after an update, a fix may be needed here.
- **Some diagrams keep their default colors.** Mermaid flowcharts, sequence diagrams, and Gantt charts follow the theme. Other Mermaid diagram types (pie, class, state, and so on) and diagrams written in the `flow` or `sequence` code blocks do not.
- **Following the OS light or dark mode** works on Windows and macOS only.

## Sources

- [Typora: About Themes](https://support.typora.io/About-Themes/)
- [Typora: Write a Custom Theme](https://theme.typora.io/doc/Write-Custom-Theme/)
- [Typora: Add Custom CSS](https://support.typora.io/Add-Custom-CSS/)
- [Typora: Custom Font](https://support.typora.io/Custom-Font/)
- [Typora: Dark Mode](https://support.typora.io/Dark-Mode/) and [Typora on Windows](https://support.typora.io/Typora-on-Windows/)
- [Typora 0.9.98 release notes](https://support.typora.io/What's-New-0.9.98/)
