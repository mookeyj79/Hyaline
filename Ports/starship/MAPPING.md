# Starship: role mapping

For maintainers. The install guide is [README.md](README.md).

## Role mapping

Palette colors, which recolor every module that uses Starship's color names:

| Starship color | Role |
|---|---|
| `red`, `bright-red` | `red` |
| `green`, `bright-green` | `green` |
| `yellow`, `bright-yellow` | `yellow` |
| `blue`, `bright-blue` | `blue` |
| `purple`, `bright-purple` | `magenta` |
| `cyan`, `bright-cyan` | `cyan` |
| `black` | Dark `raised_flat`, Light `text` |
| `bright-black` | `text_muted` |
| `white` | Dark `text_dim`, Light `line` |
| `bright-white` | Dark `text`, Light `raised_flat` |

These match the terminal ports' ANSI colors exactly, so the prompt looks the same whether Starship or the terminal picks the color.

Extra palette names, for user module styles:

| Palette name | Role |
|---|---|
| `text`, `text_dim`, `text_muted` | the same roles |
| `accent`, `on_accent` | the same roles |
| `magenta`, `orange` | the same roles |
| `panel` | `panel_flat` |
| `raised` | `raised_flat` |
| `line` | `line` |

Module styles the port changes:

| Module | Starship default | Hyaline | Why |
|---|---|---|---|
| `git_status` | `bold red` | `bold yellow` | Modified files are a change, not a failure |
| `os` | `bold white` | `bold text_dim` | `white` is a background tone in Light |
| `shell` | `white bold` | `bold text_dim` | Same |
| `memory_usage` | `bold dimmed white` | `bold dimmed text_dim` | Same |

Defaults that already fit and are left alone: `character` (green on success, red on failure), `directory` (cyan, a path), `cmd_duration` (yellow), `jobs` and `sudo` (blue), `git_branch` (purple, so `magenta`).

## Gaps and trade-offs

- **No glass.** Starship is a prompt with no background of its own, so the port is Tier 2. Glass comes from the terminal port.
- **No alpha.** Starship takes `#rrggbb` only, so translucent roles use their flat values.
- **Language modules keep Starship's default hues.** Restyling 100+ modules would make the file hard to merge into existing configs. A few, such as `purescript`, default to `white`, which is a background tone (`line`) in Light.

## Research

- [Starship source, `src/config.rs`](https://github.com/starship/starship/blob/master/src/config.rs): palette names are checked before built-in color names, and style words are lowercased first, so palette keys must be lowercase.
- Port studied: [Catppuccin for Starship](https://github.com/catppuccin/starship), MIT. Method only: one palette table per flavor, chosen with the `palette` line. No files or colors reused.
