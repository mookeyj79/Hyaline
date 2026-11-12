# Hyaline for Starship

**Tier:** 2 Flat
**Variants:** Hyaline Dark, Hyaline Light
**Tested with:** not yet tested on a real machine. Built from the official docs and Starship's source (see Sources).

| Hyaline Dark | Hyaline Light |
|---|---|
| ![Hyaline Dark](screenshots/dark.png) | ![Hyaline Light](screenshots/light.png) |

<!-- Screenshots are added by hand. Leave the paths in place. -->

Starship is a prompt, not a window. It draws colored text on your terminal's background, so it has no surface of its own to make glass. The glass comes from the terminal. Pair this port with a Hyaline terminal port, such as [Windows Terminal](../windows-terminal/README.md), on the same variant.

The port is a Starship color palette. It redefines Starship's eight color names (`red`, `green`, `blue`, and so on) and their `bright-` versions, so every module picks up Hyaline without further setup.

## Before you start

- Starship 1.11 or later (palettes were added in 1.11). Check it with `starship --version`.
- Starship already set up in your shell. If not, follow the [Starship install guide](https://starship.rs/guide/) first.
- A terminal that shows 24-bit color. Windows Terminal, iTerm2, and most modern terminals do.

## Install

Starship reads one file, `starship.toml`, in the `.config` folder of your home folder.

| OS | Path |
|---|---|
| Windows | `%USERPROFILE%\.config\starship.toml` |
| macOS, Linux | `~/.config/starship.toml` |

### If you have no starship.toml yet

1. Download or clone this repo.
2. Open your home folder. On Windows, open File Explorer, type `%USERPROFILE%` in the address bar, and press **Enter**.
3. If there is no `.config` folder, create one. On Windows, if File Explorer refuses a name starting with a dot, run `mkdir -Force ~/.config` in PowerShell.
4. Copy `Ports/starship/dist/dark/starship-dark.toml` into `.config`. For Light, copy `Ports/starship/dist/light/starship-light.toml` instead.
5. Rename the copy to `starship.toml`.
6. Open a new terminal tab. The prompt now uses Hyaline colors.

### If you already have a starship.toml

1. Open your `starship.toml` in a text editor.
2. Open `Ports/starship/dist/dark/starship-dark.toml` (or the Light file).
3. Copy the line `palette = "Hyaline Dark"` and paste it near the top of your file, above every `[section]`. If your file already has a `palette = ` line, replace it.
4. Copy the whole `[palettes."Hyaline Dark"]` table from the end of the Hyaline file and paste it at the end of yours.
5. Optional: copy the `[git_status]`, `[os]`, `[shell]`, and `[memory_usage]` sections too. [Role mapping](#role-mapping) explains why. If your file already has one of these sections, copy only its `style = ` line.
6. Save, then open a new terminal tab.

Files to use:

- Hyaline Dark: `dist/dark/starship-dark.toml`
- Hyaline Light: `dist/light/starship-light.toml`

## Set the font

Hyaline uses [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads). If it is not installed yet, follow [Font](../../README.md#font) in the main README.

Starship cannot set a font. It uses your terminal's font, so set **FiraCode Nerd Font Mono** in the terminal. The Windows Terminal port already does this. Starship's icons need a Nerd Font; without one, some symbols show as boxes.

## Check that it worked

1. Run `starship print-config palette`. It prints `palette = "Hyaline Dark"` (or Light).
2. Open a git folder with an edited file. The `❯` arrow is Hyaline green, the folder path is cyan, and the git status marks are yellow.
3. Run a command that fails, such as `git nope`. The arrow turns Hyaline red.

## Switch between Dark and Light

Starship cannot follow your OS light or dark setting. You pick the variant in `starship.toml`.

To make switching a one-line change:

1. Install one variant as above.
2. Open the other variant's file and copy its `[palettes."Hyaline ..."]` table to the end of your `starship.toml` too. You now have both tables.
3. To switch, set the `palette = ` line to `"Hyaline Dark"` or `"Hyaline Light"` and save.
4. Open a new terminal tab.

Switch your terminal's color scheme at the same time, so the prompt matches the background behind it.

## Uninstall

1. Open `starship.toml`.
2. Delete the `palette = "Hyaline ..."` line.
3. Delete the `[palettes."Hyaline Dark"]` and `[palettes."Hyaline Light"]` tables.
4. Delete the `[git_status]`, `[os]`, `[shell]`, and `[memory_usage]` sections if you copied them from Hyaline.
5. Save and open a new terminal tab. Starship is back to its default colors.

If you used the Hyaline file as your whole config, you can delete `starship.toml` instead.

## Troubleshooting

- **Colors did not change**: the `palette = ` line must be above every `[section]`, and the name must match the table name exactly, including the space and capital letters.
- **Starship logs `Could not find color palette`**: the `[palettes."..."]` table is missing, or its name differs from the `palette = ` line.
- **Colors look dull or slightly off**: the terminal is not showing 24-bit color. On Windows, use Windows Terminal rather than the old console window.
- **The prompt is hard to read in Light**: the terminal is still on a dark scheme. Switch the terminal to Hyaline Light too.
- **Starship ignores `starship.toml`**: the `STARSHIP_CONFIG` environment variable points somewhere else. Edit that file, or remove the variable.

---

## Reference

### Role mapping

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

Extra palette names, for your own module styles (for example `style = "bold accent"`):

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

### Known gaps

- **No glass.** Starship has no background of its own. Glass comes from the terminal port.
- **Cannot follow the OS light or dark setting.** Switching is a one-line edit.
- **Language modules keep Starship's default hues.** For example `rust` is red and `python` is yellow, though neither means failure or change. Restyling 100+ modules would make the file hard to merge into existing configs. A few, such as `purescript`, default to `white`, which is faint in Light; set their `style` to `text_dim` if you use them.
- **No alpha.** Starship takes `#rrggbb` only, so translucent roles use their flat values.
- **Not tested on a real machine yet.** Screenshots and a tested version are still to come.

### Sources and credits

- [Starship configuration](https://starship.rs/config/): config file location, `STARSHIP_CONFIG`, `palette` and `palettes`, module default styles
- [Starship advanced configuration](https://starship.rs/advanced-config/): style strings, color names, the `bright-` prefix, hex colors
- [Starship source, `src/config.rs`](https://github.com/starship/starship/blob/master/src/config.rs): palette names are checked before built-in color names, and style words are lowercased first, so palette keys must be lowercase
- [Starship changelog](https://github.com/starship/starship/blob/master/CHANGELOG.md): palettes added in 1.11.0
- Port studied: [Catppuccin for Starship](https://github.com/catppuccin/starship), MIT. Method only: one palette table per flavor, chosen with the `palette` line. No files or colors reused.
