# Claude Code: role mapping

For maintainers. The install guide is [README.md](README.md).

## Role mapping

Text and accents:

| Claude Code token | Role |
|---|---|
| `claude`, `claudeShimmer` (spinner, assistant label) | `accent` |
| `claudeBlue_FOR_SYSTEM_SPINNER`, its shimmer | `blue` |
| `text` | `text` |
| `inverseText` (text on colored badges) | `on_accent` |
| `inactive`, `inactiveShimmer` (hints, timestamps) | `text_muted` |
| `subtle` (faint borders and secondary text) | `text_muted` |
| `suggestion` (autocomplete, picker highlight) | `accent` |
| `permission`, `permissionShimmer` (dialog borders) | `accent` |
| `remember` (memory and `CLAUDE.md` marks) | `cyan` |
| `skill` | `magenta` |

Status:

| Claude Code token | Role |
|---|---|
| `success` | `green` |
| `error` | `red` |
| `warning`, `warningShimmer` (also the auto mode mark) | `yellow` |
| `merged` | `magenta` |

Input box and modes:

| Claude Code token | Role |
|---|---|
| `promptBorder`, `promptBorderShimmer` | `text_muted` |
| `planMode` | `magenta` |
| `autoAccept`, `autoAcceptShimmer` (accept-edits mode) | `yellow` |
| `bashBorder` (`!` shell commands) | `orange` |
| `ide` | `cyan` |
| `fastMode`, `fastModeShimmer` | `orange` |
| `effortUltra` | `magenta` |

Surfaces and highlights. A wash here is the role at the variant's wash strength, already mixed over `panel_flat`, because Claude Code takes solid colors only:

| Claude Code token | Role |
|---|---|
| `diffAdded`, `diffAddedWord` | `green` wash |
| `diffRemoved`, `diffRemovedWord` | `red` wash |
| `diffAddedDimmed`, `diffRemovedDimmed` (rejected edits) | `raised_flat` |
| `userMessageBackground` | `raised_flat` |
| `userMessageBackgroundHover` | `accent` wash |
| `selectionBg` | `accent` wash |
| `bashMessageBackgroundColor` | `orange` wash |
| `memoryBackgroundColor` | `cyan` wash |
| `composerSidebarBackground` | `raised_flat` |

Usage meter and labels:

| Claude Code token | Role |
|---|---|
| `rate_limit_fill` | `accent` |
| `rate_limit_empty` | `line` |
| `briefLabelYou` | `text_dim` |
| `briefLabelClaude` | `accent` |

Subagent colors (names, not meanings):

| Claude Code token | Role |
|---|---|
| `red_FOR_SUBAGENTS_ONLY` | `red` |
| `blue_FOR_SUBAGENTS_ONLY` | `blue` |
| `green_FOR_SUBAGENTS_ONLY` | `green` |
| `yellow_FOR_SUBAGENTS_ONLY` | `yellow` |
| `purple_FOR_SUBAGENTS_ONLY`, `pink_FOR_SUBAGENTS_ONLY` | `magenta` |
| `orange_FOR_SUBAGENTS_ONLY` | `orange` |
| `cyan_FOR_SUBAGENTS_ONLY` | `cyan` |

The `ultrathink` rainbow (`rainbow_*` and `rainbow_*_shimmer`, 14 tokens) is all `magenta`.

Every shimmer token takes the same role as its base token, so animated text keeps one color.

## Gaps and trade-offs

- **No glass.** Claude Code has no background of its own. Glass comes from the terminal port, so this is Tier 2.
- **Code colors are not themeable.** The built-in highlighter is out of reach of custom themes, so syntax roles are not applied to code blocks, diffs, or file previews.
- **Washes assume a Hyaline terminal.** Claude Code takes solid colors only, so every wash is pre-mixed over `panel_flat`. On another background they look off.
- **No word-level diff emphasis.** `diffAddedWord` and `diffRemovedWord` get the same wash as the line. A stronger wash under colored code would fail the contrast floor.
- **No shimmer and no rainbow.** Shimmer tokens take their base token's role, and the `ultrathink` rainbow is all `magenta`. Hyaline does not use gradients on text.
- **Cannot follow the OS light or dark setting.** The `auto` option only switches between built-in themes.
- **Left at Claude Code's defaults:** the onboarding mascot colors (`clawd_body`, `clawd_background`) and a few tokens the docs do not describe (`background`, `professionalBlue`, `chromeYellow`). They come from the `dark` or `light` base theme.
- **The user message card is faint in Light.** `raised_flat` is only a shade lighter than the Light panel.
- **Not tested on a real machine yet.** Screenshots and a tested version are still to come.

## Research

- Token list taken from Claude Code 2.1.322's built-in themes, including tokens the docs leave out. The [custom theme docs](https://code.claude.com/docs/en/terminal-config#create-a-custom-theme) cover file location, `name`, `base`, `overrides`, color formats, the token reference, and live reload.
- Settings facts used in the README: the `custom:<slug>` value and the `auto` option ([`theme`](https://code.claude.com/docs/en/settings-reference#theme)), `~/.claude` on Windows, `CLAUDE_CONFIG_DIR`, and settings precedence ([settings](https://code.claude.com/docs/en/settings)). Plugins can ship the same theme files ([plugin components](https://code.claude.com/docs/en/plugins/components#themes-and-output-styles)).
- Port studied: [Dracula for Claude Code](https://github.com/dracula/claude-code), MIT. It is a built-in code theme for the desktop app and claude.ai, not a CLI theme file, so it confirmed only that those surfaces cannot load outside themes. No Catppuccin, Nord, or Rosé Pine port of the CLI custom theme format existed to study. No files or colors reused.
