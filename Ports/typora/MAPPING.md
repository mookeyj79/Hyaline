# Typora: role mapping

For maintainers. The install guide is [README.md](README.md).

## Role mapping

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

Code blocks (CodeMirror tokens), per the syntax mapping in PHILOSOPHY.md:

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

Source code mode (the whole file as Markdown):

| Element | Role |
|---|---|
| Headings | `blue` |
| Link text | `accent` |
| URLs | `cyan` |
| Inline and fenced code | `orange` |
| Syntax marks, quotes | `text_dim` |

Mermaid diagrams:

| Element | Role |
|---|---|
| Nodes and boxes | `panel_flat` fill, `text_dim` outline |
| Lines and arrows | `text_dim` |
| Labels | `text` |
| Notes | `yellow` outline |
| Gantt bars: planned, running, done, critical | `magenta`, `blue`, `green`, `red` |
| Gantt bar labels | `panel_flat` |

## Gaps and trade-offs

- **No glass.** Typora's window is opaque, and themes cannot make it see-through or blurred. Tier 2, flat roles throughout.
- **Colored text stays on the panel.** In Hyaline Dark, `raised_flat` is too light for colored text to pass the contrast floor, so code blocks and inline code use `panel_flat` with a `line` border instead of a lifted background.
- **Some of Typora's own UI keeps its look.** Parts of the preferences window, the export dialog, and a few icons are styled by Typora and only partly follow the theme.
- **Typora's class names are not a stable API.** Typora says its CSS variables "may change in future". A Typora update can leave a part unstyled until the port catches up.
- **Diagrams.** Flowcharts, sequence diagrams, and Gantt charts are covered. Other Mermaid diagram types and the older `flow` and `sequence` blocks keep their default colors.
- **The OS mode switch** works on Windows and macOS only.
- **Not tested on a real machine yet.** Built from Typora's official docs and its built-in Night theme. Screenshots and a tested version are still to come.

## Research

- What each official doc page was used for: About Themes (Open Theme Folder, file naming, how menu names are built, separate themes for light and dark mode); Write a Custom Theme (CSS variables, `#write`, `.md-fences`, `.cm-s-inner`, `.cm-s-typora-default`, debug tools); Add Custom CSS (`base.user.css` and load order); Custom Font (`--monospace`, `body` font, `#typora-source`, font size setting); Dark Mode and Typora on Windows (following the OS mode); 0.9.98 release notes (themes per light and dark mode).
- Theme studied: Typora's built-in [Night theme](https://github.com/typora/typora-default-themes) (no license stated), for which UI selectors a dark theme must cover. Selector names only; no rules or colors reused.
- Ports studied: [Catppuccin for Typora](https://github.com/vari-sh/Catppuccin-Typora) (community port) and [Dracula for Typora](https://github.com/Teyler7/dracula-typora-theme). Method only: one CSS file per variant, installed through Open Theme Folder. No files or colors reused.
