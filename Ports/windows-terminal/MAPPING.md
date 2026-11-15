# Windows Terminal: role mapping

For maintainers. The install guide is [README.md](README.md).

## Role mapping

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

## Gaps and trade-offs

- **One opacity for both variants.** `opacity` is a profile setting, not part of the scheme. When following Windows, use Hyaline Light's denser `panel` alpha, so Hyaline Dark is a little more solid than on other glass ports.
- **Tab and menu text color** comes from `applicationTheme`, so chrome text is not a palette role.
- **Selected text** keeps its own color on the `accent` selection. There is no selection text color setting. Check that selected text is readable when taking screenshots, especially in Light.
- **Window frame colors** (`frame`, `unfocusedFrame`) only work in Windows Terminal Preview on Windows 11, per the docs.
- **Bright ANSI colors** reuse their normal roles on purpose (ADR 0001).
- **Scrollbar, command palette, and settings screen** follow `applicationTheme`, not palette roles.
- **Not tested on a real machine yet.** Screenshots and a tested version are still to come.

## Research

- Ports studied: [Catppuccin for Windows Terminal](https://github.com/catppuccin/windows-terminal) and [Rosé Pine for Windows Terminal](https://github.com/rose-pine/windows-terminal), both MIT. Method only: one scheme and one theme per variant, and leaving `tab.unfocusedBackground` unset. No files or colors reused.
- Docs facts behind the mapping: themes hold `tabRow`, `tab`, `window`, Mica, and `#rrggbbaa` colors, and `theme` can be a light/dark pair ([Themes](https://learn.microsoft.com/windows/terminal/customize-settings/themes)). `colorScheme` can be a light/dark pair, and `opacity`, `useAcrylic`, `font`, and `adjustIndistinguishableColors` are profile settings ([Appearance profile settings](https://learn.microsoft.com/windows/terminal/customize-settings/profile-appearance)). Fragments can hold schemes but not themes ([JSON fragment extensions](https://learn.microsoft.com/windows/terminal/json-fragment-extensions)).
