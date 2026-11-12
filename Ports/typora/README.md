# Hyaline for Typora

**Tier:** 2 Flat
**Variants:** Hyaline Dark, Hyaline Light
**Tested with:** not yet tested on a real machine. Built from Typora's official docs and its built-in Night theme (see Sources).

| Hyaline Dark | Hyaline Light |
|---|---|
| ![Hyaline Dark](screenshots/dark.png) | ![Hyaline Light](screenshots/light.png) |

<!-- Screenshots are added by hand. Leave the paths in place. -->

The port is two Typora themes, one CSS file per variant. They show up in Typora's **Themes** menu as **Hyaline Dark** and **Hyaline Light**. Typora cannot make its window see-through, so the port uses the solid (flat) Hyaline colors.

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

---

## Reference

### Role mapping

Typora variables:

| Typora variable | Role |
|---|---|
| `--bg-color` | `panel_flat` |
| `--text-color` | `text` |
| `--md-char-color` (Markdown syntax marks) | `text_dim` |
| `--meta-content-color` (link and image addresses) | `cyan` |
| `--side-bar-bg-color` | `chrome_flat` |
| `--control-text-color`, `--control-text-hover-color` | `text` |
| `--window-border` | `line` |
| `--item-hover-bg-color` / `--item-hover-text-color` | `raised_flat` / `text` |
| `--active-file-bg-color` / `--active-file-text-color` | `accent` / `on_accent` |
| `--primary-color`, `--primary-btn-border-color` | `accent` |
| `--primary-btn-text-color` | `on_accent` |
| `--select-text-bg-color`, `--search-select-bg-color` | `accent` |
| `--rawblock-edit-panel-bd` | `raised_flat` |
| `--monospace` | FiraCode Nerd Font Mono |

Surfaces:

| Part of Typora | Role |
|---|---|
| Writing area, code blocks, inputs | `panel_flat` |
| Sidebar (files, outline), title bar, footer | `chrome_flat`, with `text` only |
| Menus, context menu, quick open, search bar, dialogs, tooltips | `raised_flat`, with `line` border |
| Borders, rules, table lines, scrollbars | `line` |
| Selected text, open file, active menu item, primary buttons | `accent` with `on_accent` |
| Modal backdrop | `backdrop` |

Writing:

| Element | Role |
|---|---|
| Body text, headings, bold | `text` |
| Blockquotes, `h6`, Markdown syntax marks, front matter | `text_dim` |
| Comments, line numbers, faded text in focus mode | `text_muted` |
| Links, footnote marks, table of contents, cursor | `accent` |
| Inline code | `orange` |
| Highlight (`==mark==`), search hits | `yellow` fill, `panel_flat` text |
| Current search hit | `accent` fill, `on_accent` text |
| Checked task box | `accent` fill, `on_accent` tick |
| Diagram errors | `red` |

Code blocks follow the syntax table in PHILOSOPHY.md:

| CodeMirror token | Role |
|---|---|
| `property`, `attribute`, `def`, `builtin`, `header` | `blue` |
| `string`, `string-2`, `positive` | `green` |
| `number` | `orange` |
| `keyword`, `atom` | `magenta` |
| `type`, `variable-3`, `link` | `cyan` |
| `tag`, `meta`, `qualifier` | `yellow` |
| `error`, `negative` | `red` |
| `operator`, `bracket`, `punctuation`, `quote`, `hr` | `text_dim` |
| `comment` | `text_muted` |
| `variable`, `variable-2` | `text` |

Source code mode (the whole file as Markdown): headings `blue`, link text `accent`, URLs `cyan`, inline and fenced code `orange`, syntax marks and quotes `text_dim`.

Mermaid diagrams: nodes and boxes `panel_flat` with `text_dim` outlines, lines and arrows `text_dim`, labels `text`, notes outlined in `yellow`. Gantt bars: planned `magenta`, running `blue`, done `green`, critical `red`, with `panel_flat` labels.

### Known gaps

- **No glass.** Typora's window is opaque, and themes cannot make it see-through or blurred.
- **Colored text stays on the panel.** In Hyaline Dark, `raised_flat` is too light for colored text to pass the contrast floor, so code blocks and inline code use the panel with a border instead of a lifted background.
- **Some of Typora's own UI keeps its look.** Parts of the preferences window, the export dialog, and a few icons are styled by Typora and only partly follow the theme.
- **Typora's class names are not a stable API.** Typora says its CSS variables "may change in future". A Typora update can leave a part unstyled until the port catches up.
- **Diagrams.** Flowcharts, sequence diagrams, and Gantt charts are covered. Other Mermaid diagram types (pie, class, state, and so on) and flowchart/sequence diagrams drawn with `flow` or `sequence` keep their default colors.
- **The OS mode switch** works on Windows and macOS only.
- **Not tested on a real machine yet.** Screenshots and a tested version are still to come.

### Sources and credits

- [Typora: About Themes](https://support.typora.io/About-Themes/): Open Theme Folder, file naming, how menu names are built, separate themes for light and dark mode
- [Typora: Write a Custom Theme](https://theme.typora.io/doc/Write-Custom-Theme/): CSS variables, `#write`, `.md-fences`, `.cm-s-inner`, `.cm-s-typora-default`, debug tools
- [Typora: Add Custom CSS](https://support.typora.io/Add-Custom-CSS/): `base.user.css` and load order
- [Typora: Custom Font](https://support.typora.io/Custom-Font/): `--monospace`, `body` font, `#typora-source`, font size setting
- [Typora: Dark Mode](https://support.typora.io/Dark-Mode/) and [Typora on Windows](https://support.typora.io/Typora-on-Windows/): following the OS mode on Windows and macOS
- [Typora 0.9.98 release notes](https://support.typora.io/What's-New-0.9.98/): themes per light and dark mode
- Theme studied: Typora's built-in [Night theme](https://github.com/typora/typora-default-themes) (no license stated), for which UI selectors a dark theme must cover. Selector names only; no rules or colors reused.
- Ports studied: [Catppuccin for Typora](https://github.com/vari-sh/Catppuccin-Typora) (community port) and [Dracula for Typora](https://github.com/Teyler7/dracula-typora-theme). Method only: one CSS file per variant, installed through Open Theme Folder. No files or colors reused.
