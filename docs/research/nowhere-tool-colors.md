# Which Nowhere tools have color settings, and in what form

Research for [issue #48](https://github.com/mookeyj79/Hyaline/issues/48), part of the map in [issue #47](https://github.com/mookeyj79/Hyaline/issues/47). Read on 2026-11-15.

The tool list comes from [Nowhere](https://github.com/mookeyj79/Nowhere) itself: [`shared/tools.json`](https://github.com/mookeyj79/Nowhere/blob/main/shared/tools.json), [`zsh/plugins.json`](https://github.com/mookeyj79/Nowhere/blob/main/zsh/plugins.json), [`powershell/modules.json`](https://github.com/mookeyj79/Nowhere/blob/main/powershell/modules.json), plus server-motd and PowerShell 7.

Every claim links to the tool's own docs. Where the docs are silent, the tool's own source file is linked and marked "(source)". Anything neither covers is under [Not verified](#not-verified).

## Answer in brief

- **Fifteen things have their own color settings worth a port:** bat, btop, eza, fzf, Neovim, git, less, nano, carapace, Zsh's line editor and its three plugins, PSReadLine, and PowerShell's `$PSStyle`.
- **Four more have color settings nobody listed:** ripgrep (`--colors`), hexyl (`HEXYL_COLOR_*`, version 0.17 and later only), Docker's build output (`BUILDKIT_COLORS`), and gh's Markdown rendering (`GLAMOUR_STYLE`). All four already print in the terminal's colors by default, so a port is optional.
- **server-motd has no color settings.** It prints three fixed terminal colors (green, yellow, red) and bold. The terminal port covers it.
- **Exact colors are accepted almost everywhere.** The exceptions are less (sixteen or 256 only) and nano (picks the nearest of 256, never exact).
- **Only two tools can tell Dark from Light on their own:** bat (0.25 and later) and Neovim. Every other tool with exact colors must be told the variant.
- **One environment variable feeds three tools.** `LS_COLORS` colors files in eza, fd, and carapace's completions, and Zsh's completion list can read it too.
- **Distro versions matter.** Ubuntu 24.04 ships bat, eza, fzf, and Neovim versions that lack the newer theme features. Debian 13 is fine except for hexyl.
- **Most settings are shell variables, not files.** That fits the planned Nowhere theme hook (`~/.config/nowhere/theme.zsh` and `theme.ps1`, [Nowhere issue 29](https://github.com/mookeyj79/Nowhere/issues/29)): one shipped file per shell and variant could carry fzf, eza, less, the Zsh plugins, PSReadLine, and `$PSStyle` together.

## Summary table

"Exact" means hex or 24-bit color. "16" means the terminal's sixteen colors, "256" the indexed palette. "Drop in" means the port can ship a file the user copies without editing their own config. "Learn from" lists ports by other themes, for method only.

| Tool | Setting | Colors accepted | Dark and Light | Windows | Linux | Drop in | Learn from |
|---|---|---|---|---|---|---|---|
| bat | `.tmTheme` file, picked by `--theme` or `BAT_THEME` | Exact | Both, with auto detection (0.25+) | `bat --config-dir`, then `themes\` | `bat --config-dir`, then `themes/` | Theme files yes, then `bat cache --build` and one setting | [Catppuccin](https://github.com/catppuccin/bat), [Rosé Pine](https://github.com/rose-pine/tm-theme), [Tokyo Night](https://github.com/folke/tokyonight.nvim/tree/main/extras/sublime) |
| btop | `.theme` file, picked by `color_theme` in `btop.conf` | Exact | Neither: one theme at a time | btop4win: `themes\` next to the exe | `~/.config/btop/themes/` | Theme file yes, then pick it | [Catppuccin](https://github.com/catppuccin/btop), [Rosé Pine](https://github.com/rose-pine/btop), [Tokyo Night](https://github.com/folke/tokyonight.nvim/tree/main/extras/btop) |
| eza | `theme.yml` (0.19.2+), or `EZA_COLORS` and `LS_COLORS` | Exact | Neither | `%APPDATA%\eza\theme.yml` (source) or `EZA_CONFIG_DIR` | `~/.config/eza/theme.yml` or `EZA_CONFIG_DIR` | Yes, the file name is fixed | [Catppuccin](https://github.com/catppuccin/eza), [Dracula](https://github.com/dracula/eza), [Rosé Pine](https://github.com/rose-pine/eza), [Tokyo Night](https://github.com/folke/tokyonight.nvim/tree/main/extras/eza), [eza-themes](https://github.com/eza-community/eza-themes) |
| fzf | `--color` in `FZF_DEFAULT_OPTS` or `FZF_DEFAULT_OPTS_FILE` | Exact, 256, or 16 | Base schemes `dark`, `light`, `base16`. No detection | Environment variable | Environment variable | No: a line in the shell profile | [Catppuccin](https://github.com/catppuccin/fzf), [Dracula](https://github.com/dracula/fzf), [Rosé Pine](https://github.com/rose-pine/fzf), [Tokyo Night](https://github.com/folke/tokyonight.nvim/tree/main/extras/fzf) |
| Neovim | `colors/<name>.lua` or `.vim`, loaded by `:colorscheme` | Exact (`guifg`) and 256 (`ctermfg`) | Both in one file through `'background'`, which the terminal UI sets when it can detect it | `~/AppData/Local/nvim/colors/` | `~/.config/nvim/colors/` | File yes, plus one `colorscheme` line | [Catppuccin](https://github.com/catppuccin/nvim), [Dracula](https://github.com/dracula/vim), [Nord](https://github.com/nordtheme/vim), [Rosé Pine](https://github.com/rose-pine/neovim), [Tokyo Night](https://github.com/folke/tokyonight.nvim) |
| git | `color.<area>.<slot>` in git config | Exact, 256, or 16 | Neither | `%USERPROFILE%\.gitconfig` | `~/.gitconfig` or `~/.config/git/config` | File yes, plus one `include.path` line | [Dracula](https://github.com/dracula/git) |
| less | `--use-color` and `-D` in `LESS`, or a lesskey file | 16 or 256. No exact colors | Neither | `LESS` variable, or `%HOME%\_lesskey` | `LESS` variable, or `~/.config/lesskey` | No: Nowhere already sets `LESS` | [Dracula man-pages](https://github.com/dracula/man-pages), an older method |
| nano | `set <part>color` and syntax `color` lines in nanorc | 16 names, or nearest of 256. Never exact | Neither | Not verified (winget ships 2.7.5) | `~/.nanorc` or `~/.config/nano/nanorc` | Syntax files yes (`include`). Interface colors no | None found in the five |
| carapace | `carapace --style`, saved in `styles.json`. Files use `LS_COLORS` | Exact, 256, or 16 | Neither | `%AppData%\carapace\styles.json` | `~/.config/carapace/styles.json` | Likely yes, see Not verified | None found |
| Zsh line editor and completion list | `zle_highlight`, and the `list-colors` style | Exact (true color terminal), 256, 16 | Neither | Not used | Shell variable and `zstyle` | No: lines in the shell profile | [Dracula](https://github.com/dracula/zsh) is a prompt theme, not this |
| zsh-syntax-highlighting | `ZSH_HIGHLIGHT_STYLES` array | Same as Zsh | Neither | Not used | Shell variable | Yes: one sourced file | [Catppuccin](https://github.com/catppuccin/zsh-syntax-highlighting), [Dracula](https://github.com/dracula/zsh-syntax-highlighting) |
| zsh-autosuggestions | `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE` | Same as Zsh | Neither | Not used | Shell variable | One line | None found |
| zsh-history-substring-search | `HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND` and `_NOT_FOUND` | Same as Zsh | Neither | Not used | Shell variable | Two lines | None found |
| PSReadLine | `Set-PSReadLineOption -Colors @{...}` | Exact, 256, or 16 | Neither | PowerShell profile | PowerShell profile | No: lines in the profile | [Catppuccin](https://github.com/catppuccin/powershell), [Dracula](https://github.com/dracula/powershell) |
| PowerShell 7 | `$PSStyle.Formatting`, `.FileInfo`, `.Progress` | Exact, 256, or 16 | Neither | PowerShell profile | PowerShell profile | No: lines in the profile | [Catppuccin](https://github.com/catppuccin/powershell) |
| ripgrep | `--colors`, in the file named by `RIPGREP_CONFIG_PATH` | Exact, 256, or 16 | Neither | File of flags, any path | File of flags, any path | Yes, if the user has no config file yet | [Dracula](https://github.com/dracula/ripgrep) |
| hexyl | `HEXYL_COLOR_*` variables (0.17+) | Exact or 16 | Neither | Environment variables | Environment variables, but apt ships 0.8.0 | No: lines in the shell profile | None found |
| docker (build output) | `BUILDKIT_COLORS` | Exact or named | Neither | Environment variable | Environment variable | One line | None found |
| gh (Markdown only) | `GLAMOUR_STYLE` | Not checked | Not checked | Environment variable | Environment variable | Not checked | [Catppuccin](https://github.com/catppuccin/glamour) |
| server-motd | None | Fixed: terminal green, yellow, red, bold | Follows the terminal | Not applicable | Not applicable | Not applicable | Not applicable |
| fd | None of its own: reads `LS_COLORS` | Whatever `LS_COLORS` holds | Follows `LS_COLORS` | Environment variable | Environment variable | Covered by the eza or `LS_COLORS` work | [Nord](https://github.com/nordtheme/dircolors), [Dracula](https://github.com/dracula/dircolors) |
| zoxide | None of its own: passes `_ZO_FZF_OPTS` to fzf | fzf's | fzf's | Environment variable | Environment variable | Covered by the fzf port | Not applicable |
| uv, gitleaks, helm, terraform, tofu | Color on or off only | Terminal's | Follows the terminal | Not applicable | Not applicable | Not applicable | Not applicable |
| kubectl | No color settings documented | None | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable |

## Three-way sort

### Needs a port

Has its own color settings that take palette values.

1. **bat**
2. **btop** (btop++ on Linux, btop4win on Windows: same theme file)
3. **eza** (and with it `LS_COLORS`, which also colors fd, carapace file completions, and optionally Zsh's completion list)
4. **fzf** (also colors zoxide's interactive picker)
5. **Neovim**
6. **git**
7. **less** (terminal colors only: 16 or 256, no exact values)
8. **nano** (cannot be exact: it approximates to the 256 palette)
9. **carapace**
10. **Zsh**: `zle_highlight` and `list-colors`
11. **zsh-syntax-highlighting**
12. **zsh-autosuggestions**
13. **zsh-history-substring-search**
14. **PSReadLine**
15. **PowerShell 7** (`$PSStyle`)

Has settings, but already prints in the terminal's colors by default, so a port is optional and small:

16. **ripgrep** (`--colors`)
17. **hexyl** (`HEXYL_COLOR_*`, only in 0.17+, so Windows only for now)
18. **docker** build output (`BUILDKIT_COLORS`)
19. **gh** Markdown rendering (`GLAMOUR_STYLE`)

Already ported: Starship, VS Code (`code`), Windows Terminal.

### Covered by the terminal port

Prints with the terminal's colors and has no setting of its own beyond on or off.

- **server-motd** (fixed green, yellow, red, and bold)
- **fd** (reads `LS_COLORS`, so it also follows the eza work)
- **zoxide** (its picker is fzf)
- **uv**, **gitleaks**, **helm**, **terraform**, **tofu**
- **gh**, apart from Markdown rendering
- **docker**, apart from build output

### Cannot be themed

- **kubectl**: its reference documents no color option or color variable.
- **PSWindowsUpdate**: no color settings found. See Not verified.
- **catppuccin-zsh-syntax-highlighting**: this pinned plugin is itself a theme. Nowhere issue 29 removes it.

## Things later tickets should know

**Variant detection.** bat and Neovim are the only tools here that ask the terminal for its background. fzf has `dark` and `light` base schemes but picks `dark` on any 256-color terminal without looking. Everything else takes one set of colors. For those, either the port uses the terminal's sixteen (and switches for free) or the user installs the file for one variant.

**The theme hook is the natural carrier.** fzf, eza (`EZA_CONFIG_DIR` or `EZA_COLORS`), less, hexyl, ripgrep (`RIPGREP_CONFIG_PATH`), bat (`BAT_THEME_DARK`, `BAT_THEME_LIGHT`), `LS_COLORS`, the Zsh variables, PSReadLine, and `$PSStyle` are all set from the shell. One file per shell per variant could hold them all. bat, btop, Neovim, git, nano, and carapace need real files in their own folders.

**`LS_COLORS` and `EZA_COLORS`.**

- eza reads `LS_COLORS` for ten file-kind codes, then `EZA_COLORS`, which overrides it and adds eza's own codes for permissions, sizes, dates, git, and so on. A `reset` entry at the start of `EZA_COLORS` drops eza's built-in extension colors. [eza_colors(5)](https://github.com/eza-community/eza/blob/main/man/eza_colors.5.md)
- fd colors by `LS_COLORS` and has no color settings of its own. [fd README](https://github.com/sharkdp/fd/blob/master/README.md)
- carapace styles file completions from `LS_COLORS`, in Zsh and PowerShell. [carapace Style](https://github.com/carapace-sh/carapace-bin/blob/master/docs/src/style.md)
- Zsh's completion list uses the same format as GNU `ls` (`ZLS_COLORS`), set through the `list-colors` style. [zsh complist](https://github.com/zsh-users/zsh/blob/master/Doc/Zsh/mod_complist.yo) Nowhere does not set `list-colors` today.
- Neither Nowhere profile sets `LS_COLORS` today, and Windows has no default for it.

**Versions on Nowhere's supported Linux releases.** From the Debian and Ubuntu archives:

| Tool | Debian 13 | Ubuntu 24.04 | What the older one lacks |
|---|---|---|---|
| bat | 0.25.0 | 0.24.0 | 0.24 has no auto detection and no `--theme-dark` or `--theme-light`. 0.25.0 ignores `BAT_THEME_DARK` and `BAT_THEME_LIGHT` (fixed in 0.26.0) |
| eza | 0.21.0 | 0.18.2 | 0.18 has no `theme.yml` (added in 0.19.2). `EZA_COLORS` only |
| fzf | 0.60.3 | 0.44.1 | 0.44 has no `FZF_DEFAULT_OPTS_FILE` (added in 0.48.0) |
| Neovim | 0.10.4 | 0.9.5 | 0.9 does not turn on `termguicolors` by itself (added in 0.10) |
| hexyl | 0.8.0 | 0.8.0 | No `HEXYL_COLOR_*` (added in 0.17.0) |
| less | 668 | 590 | Nothing found |
| nano | 8.4 | 7.2 | Nothing found (`#rgb` arrived in 6.0) |
| btop | 1.3.2 | 1.3.0 | Nothing found |
| git | 2.47.3 | 2.43.0 | Nothing found for six-digit hex |

## Per tool

### bat

- Themes are `.tmTheme` files in `$(bat --config-dir)/themes`. After copying, run `bat cache --build`. The theme takes the file's name. `.sublime-color-scheme` files are not supported. [bat README, Adding new themes](https://github.com/sharkdp/bat/blob/master/README.md#adding-new-themes)
- Pick a theme with `--theme` or `BAT_THEME`. The default `auto` picks a dark or light theme from the terminal's colors, and `--theme-dark`, `--theme-light`, `BAT_THEME_DARK`, and `BAT_THEME_LIGHT` name the two. [bat long help](https://github.com/sharkdp/bat/blob/master/doc/long-help.txt)
- Auto detection arrived in 0.25.0. In 0.25.0 the two `BAT_THEME_*` variables were ignored, fixed in 0.26.0. [bat CHANGELOG](https://github.com/sharkdp/bat/blob/master/CHANGELOG.md)
- Flags can also go in bat's config file. Its path is `bat --config-file`, or set `BAT_CONFIG_PATH` or `BAT_CONFIG_DIR`. [bat README, Configuration file](https://github.com/sharkdp/bat/blob/master/README.md#configuration-file)
- Themes use 24-bit color. bat needs `COLORTERM` set to `truecolor` or `24bit` to send it. Three built-in themes (`ansi`, `base16`, `base16-256`) use only the terminal's colors. [bat README, 8-bit themes](https://github.com/sharkdp/bat/blob/master/README.md#8-bit-themes)
- On some Debian and Ubuntu releases the binary is `batcat`. [bat README](https://github.com/sharkdp/bat/blob/master/README.md#on-ubuntu-using-apt)

### btop

- Themes are `.theme` files of `theme[key]="value"` lines. Values are `#RRGGBB`, a two-digit grey `#BW`, or decimal `r g b`. [theme file header](https://github.com/aristocratos/btop/blob/main/themes/nord.theme)
- User themes go in `$XDG_CONFIG_HOME/btop/themes` or `~/.config/btop/themes`. `color_theme` in `btop.conf` names the file. `theme_background = false` leaves the terminal background showing. [btop README](https://github.com/aristocratos/btop/blob/main/README.md#themes)
- `truecolor = false` converts to 256. A real TTY, or `--tty`, forces 16 colors and the built-in TTY theme. [btop README](https://github.com/aristocratos/btop/blob/main/README.md)
- No dark and light pair and no detection: one theme name at a time.
- On Windows, Nowhere installs btop4win. It reads the same theme files from a `themes` folder beside `btop4win.exe`, and keeps `btop.conf` there too. [btop4win README](https://github.com/aristocratos/btop4win/blob/master/README.md#themes)

### eza

- `EZA_COLORS` and `LS_COLORS` hold `key=SGR codes` pairs. The man page documents 16-color codes and `38;5;n`. [eza_colors(5)](https://github.com/eza-community/eza/blob/main/man/eza_colors.5.md) The parser also accepts `38;2;r;g;b`. [lsc.rs](https://github.com/eza-community/eza/blob/main/src/theme/lsc.rs) (source)
- `theme.yml` sets the same things with named fields. eza looks in `EZA_CONFIG_DIR`, otherwise `$XDG_CONFIG_HOME/eza`. The file must be named `theme.yml`. [eza_colors-explanation(5)](https://github.com/eza-community/eza/blob/main/man/eza_colors-explanation.5.md)
- `theme.yml` colors can be names, 256 indexes, or `#rrggbb`. [config.rs](https://github.com/eza-community/eza/blob/main/src/options/config.rs) (source). 0.23.5 lists a fix to "Color code parsing in theme.yml". [eza CHANGELOG](https://github.com/eza-community/eza/blob/main/CHANGELOG.md)
- On Windows the default folder comes from the `dirs` crate's config directory, which is `%APPDATA%`. [config.rs](https://github.com/eza-community/eza/blob/main/src/options/config.rs) (source). The man page names only the XDG path.
- No dark and light pair and no detection. Pointing `EZA_CONFIG_DIR` at a per-variant folder is the documented way to switch.

### fzf

- `--color=[BASE_SCHEME][,NAME[:COLOR][:ATTR]]...`. Base schemes are `dark`, `light`, `base16` (alias `16`), and `bw`. The default is `dark` on a 256-color terminal, otherwise `base16`. Colors are `-1` (terminal default), `0` to `255`, the sixteen names, or `#rrggbb`. [fzf man page](https://github.com/junegunn/fzf/blob/master/man/man1/fzf.1)
- Defaults come from `FZF_DEFAULT_OPTS_FILE`, then `FZF_DEFAULT_OPTS`, then the command line. [fzf man page](https://github.com/junegunn/fzf/blob/master/man/man1/fzf.1), [fzf CHANGELOG 0.48.0](https://github.com/junegunn/fzf/blob/master/CHANGELOG.md)
- No detection of the terminal background is documented.
- `base16` uses only the terminal's sixteen, and was retuned in 0.66 to work on both dark and light terminals. [fzf CHANGELOG](https://github.com/junegunn/fzf/blob/master/CHANGELOG.md)
- `FZF_DEFAULT_OPTS_FILE` is one file for all of the user's defaults, so a port that ships it would take over more than colors.

### Neovim

- A color scheme is `colors/<name>.vim` or `colors/<name>.lua` on the runtime path, loaded with `:colorscheme <name>`. [syntax.txt](https://github.com/neovim/neovim/blob/master/runtime/doc/syntax.txt)
- The config folder is `~/.config/nvim` on Unix and `~/AppData/Local/nvim` on Windows. [starting.txt](https://github.com/neovim/neovim/blob/master/runtime/doc/starting.txt)
- `'background'` is `dark` or `light`. The terminal UI sets it at startup if it can detect the background color, unless the user set it. One color scheme can serve both variants by reading it. [options.txt](https://github.com/neovim/neovim/blob/master/runtime/doc/options.txt)
- `'termguicolors'` turns on 24-bit color (`guifg`, `guibg`). Neovim enables it by itself when the terminal supports it, from 0.10. [options.txt](https://github.com/neovim/neovim/blob/master/runtime/doc/options.txt), [news for 0.10](https://github.com/neovim/neovim/blob/v0.10.0/runtime/doc/news.txt)

### git

- Colors are config values under `color.branch.<slot>`, `color.diff.<slot>`, `color.decorate.<slot>`, `color.grep.<slot>`, `color.interactive.<slot>`, `color.status.<slot>`, and a few more. [git config, color](https://github.com/git/git/blob/master/Documentation/config/color.adoc)
- A value is up to two colors plus attributes. Colors are the eight names, their `bright` forms, `0` to `255`, or `#rrggbb`. [git config, Values](https://github.com/git/git/blob/master/Documentation/config.adoc)
- `include.path` pulls in another file, so a port can ship one file and the user adds one line. [git config, Includes](https://github.com/git/git/blob/master/Documentation/config.adoc)
- No dark and light pair and no detection.

### less

- `--use-color` turns color on. `-Dxcolor` sets the color of one kind of text: search results, prompts, errors, line numbers, and so on. [less man page](https://github.com/gwsw/less/blob/master/less.nro.VER)
- A color is a 4-bit string (one or two letters, uppercase for bright) or an 8-bit string (one or two numbers, `CSI 38;5` values). There is no 24-bit form. [less man page](https://github.com/gwsw/less/blob/master/less.nro.VER)
- On Windows `-D` behaves differently: lowercase selectors also touch text colored by `-R`, numbers after a lowercase selector mean console attributes, and `-Da` brings it closer to the Unix behavior. [less man page](https://github.com/gwsw/less/blob/master/less.nro.VER)
- Options come from the `LESS` variable. Nowhere sets `LESS='-R -F -X'` in both shells, so a port has to add to it, not replace it.
- A lesskey file can set `LESS` in its `#env` section, but that value replaces the system variable, and `+=` can only extend a value defined in the same file. Paths: `~/.config/lesskey` or `~/.lesskey`, and `%HOME%\_lesskey` on Windows. [lesskey man page](https://github.com/gwsw/less/blob/master/lesskey.nro.VER), [less man page](https://github.com/gwsw/less/blob/master/less.nro.VER)
- `LESS_TERMCAP_xx` variables override terminal capabilities. Other themes use them to color man pages. [less man page](https://github.com/gwsw/less/blob/master/less.nro.VER)

### nano

- Interface colors are `set titlecolor`, `statuscolor`, `promptcolor`, `minicolor`, `keycolor`, `functioncolor`, `numbercolor`, `selectedcolor`, `stripecolor`, `scrollercolor`, `spotlightcolor`, and `errorcolor`, each `fg,bg`. Syntax colors are `color` lines inside `syntax` blocks. [nanorc(5)](https://www.nano-editor.org/dist/latest/nanorc.5.html)
- Colors are eight names, their `light` forms, and on 256-color terminals 24 more names or a three-digit `#rgb`. The `#rgb` form "tells nano to select from the available palette the color that approximates the given values". So nano never sends an exact color. [nanorc(5)](https://www.nano-editor.org/dist/latest/nanorc.5.html)
- nano reads `~/.nanorc`, or `$XDG_CONFIG_HOME/nano/nanorc`, or `~/.config/nano/nanorc`. `include` reads syntax files. [nanorc(5)](https://www.nano-editor.org/dist/latest/nanorc.5.html)
- `#rgb` arrived in nano 6.0. [nano NEWS](https://www.nano-editor.org/dist/latest/NEWS)
- On Windows, Nowhere's winget id installs nano 2.7.5, a 2017 build. [winget manifest](https://github.com/microsoft/winget-pkgs/tree/master/manifests/g/GNU/Nano/2.7.5) The current nanorc page does not describe it.
- No dark and light pair and no detection.

### carapace

- `carapace --style 'key=value'` sets a style, for example `carapace.Value` and `carapace.Description`. Values are attributes plus a color: the eight names, `bright-` forms, `color0` to `color255`, or `#RRGGBB`. Styling works in Zsh and PowerShell, among others. [carapace Style](https://github.com/carapace-sh/carapace-bin/blob/master/docs/src/style.md)
- File completions are styled from `LS_COLORS`. [carapace Style](https://github.com/carapace-sh/carapace-bin/blob/master/docs/src/style.md)
- Styles are saved to `styles.json` in carapace's config folder: `$XDG_CONFIG_HOME/carapace` on every system if set, otherwise `~/.config/carapace` on Linux and `%AppData%\carapace` on Windows. [UserConfigDir](https://github.com/carapace-sh/carapace-bin/blob/master/docs/src/setup/userConfigDir.md), [config reference](https://github.com/carapace-sh/carapace/blob/master/skills/carapace-dev/references/config-env.md)
- The docs say the default look "depends on your terminal color scheme". No dark and light pair.

### Zsh, and its three plugins

- All four take the same value format, Zsh's character highlighting: `fg=` and `bg=` with a color name, a number `0` to `255`, or a `#rrggbb` hex triplet, plus `bold`, `underline`, and so on. Hex needs a true color terminal, or the `zsh/nearcolor` module to approximate. [zshzle, Character Highlighting](https://github.com/zsh-users/zsh/blob/master/Doc/Zsh/zle.yo)
- Zsh itself: the `zle_highlight` array colors the region, incremental search, pasted text, and special characters. [zshzle](https://github.com/zsh-users/zsh/blob/master/Doc/Zsh/zle.yo) The completion list is colored through the `list-colors` style in `LS_COLORS` format. [zsh complist](https://github.com/zsh-users/zsh/blob/master/Doc/Zsh/mod_complist.yo)
- zsh-syntax-highlighting: the `ZSH_HIGHLIGHT_STYLES` associative array, one entry per token kind. [main highlighter docs](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md)
- zsh-autosuggestions: `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE`, default `fg=8`. [README](https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md#suggestion-highlight-style)
- zsh-history-substring-search: `HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND` (default bold white on magenta) and `HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND` (default bold white on red). [README](https://github.com/zsh-users/zsh-history-substring-search/blob/master/README.md)
- None has a dark and light pair or detection. All are shell variables, so they belong in one sourced file. Nowhere today hardcodes `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE` and loads Catppuccin's file for the highlighter. Nowhere issue 29 replaces both with terminal colors.

### PSReadLine

- `Set-PSReadLineOption -Colors` takes a hash table. Keys include `Command`, `Comment`, `Keyword`, `String`, `Operator`, `Variable`, `Parameter`, `Type`, `Number`, `Member`, `Error`, `Emphasis`, `Selection`, `InlinePrediction`, `ListPrediction`, and `ListPredictionSelected`. [Set-PSReadLineOption](https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption)
- A value is a `ConsoleColor` or an ANSI escape sequence, including 256 and 24-bit color and background. [Set-PSReadLineOption](https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption)
- It is a command, not a file, so it runs from the profile: `$HOME\Documents\PowerShell\` on Windows, `~/.config/powershell/` on Linux. [about_Profiles](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles)
- No dark and light pair and no detection.

### PowerShell 7 (`$PSStyle`)

- `$PSStyle.Formatting` colors errors, warnings, verbose and debug messages, and list and table headers. `$PSStyle.FileInfo` colors directories, links, executables, and file extensions in listings. `$PSStyle.Progress` colors the progress bar. [about_ANSI_Terminals](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_ansi_terminals)
- Values are escape sequences. `$PSStyle.Foreground.FromRgb()` and `$PSStyle.Background.FromRgb()` give 24-bit color. [about_ANSI_Terminals](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_ansi_terminals)
- Set from the profile, like PSReadLine. No dark and light pair and no detection.
- `Ports/ports.json` has no PowerShell entry today. The planned `zsh` entry lists macOS and Linux.

### ripgrep

- `--colors '{type}:{attribute}:{value}'`, with types `path`, `line`, `column`, `highlight`, and `match`. Values are the eight names, a 256 index, or `r,g,b`. [ripgrep flag definitions](https://github.com/BurntSushi/ripgrep/blob/master/crates/core/flags/defs.rs) (source of the man page)
- Flags can live in a file named by `RIPGREP_CONFIG_PATH`. ripgrep looks nowhere else. [ripgrep GUIDE](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file)

### hexyl

- `HEXYL_COLOR_ASCII_PRINTABLE`, `_ASCII_WHITESPACE`, `_ASCII_OTHER`, `_NULL`, `_NONASCII`, and `_OFFSET` take the eight names, `bright` forms, or `#rrggbb`. [hexyl README](https://github.com/sharkdp/hexyl/blob/master/README.md)
- The variables are in the 0.17.0 README and not in the 0.16.0 one. Debian 13 and Ubuntu 24.04 ship 0.8.0. winget has 0.17.0.

### docker

- `BUILDKIT_COLORS` sets the colors of build progress output, as `run=...:error=...:cancel=...:warning=...`, with RGB values or predefined names. [Docker build variables](https://docs.docker.com/build/building/variables/#buildkit_colors)
- No other color setting was found for the Docker CLI.

### gh

- `GLAMOUR_STYLE` picks the style for rendered Markdown. `GH_ACCESSIBLE_COLORS` (preview) switches to "customizable, 4-bit accessible colors". `GH_COLOR_LABELS` shows labels in their own RGB colors. Otherwise only `NO_COLOR`, `CLICOLOR`, and `CLICOLOR_FORCE`. [gh help environment](https://github.com/cli/cli/blob/trunk/pkg/cmd/root/help_topic.go) (source of `gh help environment`)

### server-motd

- Pinned in `tools.json` at commit `c4f3428`, server role only.
- Status maps to a fixed escape code: OK `32`, WARN `33`, CRIT and UNAVAILABLE `31`, INFO none. Titles are bold (`1`). [render.py](https://github.com/mookeyj79/Server-MOTD/blob/c4f34288e886db77bf48ac1c3e875f22866277b9/src/server_motd/render.py) (source)
- The only color control is `--color auto|always|never`. [configuration.md](https://github.com/mookeyj79/Server-MOTD/blob/c4f34288e886db77bf48ac1c3e875f22866277b9/docs/configuration.md) The config file has no color keys.
- So it follows the terminal port, and it uses the roles the way PHILOSOPHY.md wants: green success, yellow caution, red failure.

### Tools with color on or off only

- **fd**: `LS_COLORS` and `NO_COLOR`. [fd README](https://github.com/sharkdp/fd/blob/master/README.md)
- **zoxide**: `_ZO_FZF_OPTS` passes options to fzf. No color settings of its own. [zoxide README](https://github.com/ajeetdsouza/zoxide/blob/main/README.md)
- **helm**: `HELM_COLOR` (`never`, `always`, `auto`) and `NO_COLOR`. [helm root.go](https://github.com/helm/helm/blob/main/pkg/cmd/root.go) (source of `helm --help`)
- **gitleaks**: `--no-color`. [gitleaks README](https://github.com/gitleaks/gitleaks/blob/master/README.md)
- **terraform**: `-no-color`. [terraform plan](https://developer.hashicorp.com/terraform/cli/commands/plan#no-color)
- **tofu**: `-no-color`. [tofu plan](https://github.com/opentofu/opentofu/blob/main/website/docs/cli/commands/plan.mdx)
- **kubectl**: the [kubectl reference](https://kubernetes.io/docs/reference/kubectl/kubectl/) has no color flag or variable.

## Not verified

- **nano on Windows.** winget's `GNU.Nano` is 2.7.5 from 2017. Where it reads its nanorc on Windows, and which color names it accepts, were not found in official docs. It predates `#rgb` (6.0).
- **nano dist page host.** `git.savannah.gnu.org` timed out from here. The nanorc page was read from `nano-editor.org` instead.
- **btop4win install folder under winget.** The README says themes sit beside the exe. Where winget puts that exe was not checked.
- **eza on Windows.** The `%APPDATA%\eza` default is read from source, not docs. Which wins when both `theme.yml` and `EZA_COLORS` are set is not documented. Hex support in `theme.yml` before 0.23.5 was not checked.
- **carapace.** The `styles.json` layout is from a reference file in the carapace repo, not the user docs. Whether a shipped `styles.json` can be copied in as is, and whether `#RRGGBB` renders in PowerShell as well as Zsh, were not tested.
- **Defaults of bat, Neovim, and fzf.** That Neovim's and bat's built-in default themes use 24-bit colors, not the terminal's, was not confirmed from docs. fzf's default `dark` scheme on 256-color terminals is documented, its exact colors are not.
- **Neovim 0.9 on Ubuntu 24.04.** Whether 0.9.5 detects the terminal background was not checked. Only the `termguicolors` change in 0.10 was confirmed.
- **less.** Whether `-D` in 590 (Ubuntu 24.04) matches the current man page was not checked. The Windows build Nowhere uses (`jftuga.less`) is a third-party build of less, and its `-D` behavior was not tested.
- **git.** The three-digit `#rgb` form is in the current docs. The version that added it was not checked, so ports should use six digits.
- **uv.** Its environment reference page was not reachable at the path tried. No color settings beyond on and off are known, but this was not confirmed from docs.
- **gh and Glamour.** The format of a custom `GLAMOUR_STYLE` and whether it detects dark and light were not read.
- **PSWindowsUpdate.** Not researched beyond its entry in `modules.json`. It is a PowerShell module, so its output most likely follows `$PSStyle`, but that is a guess.
- **Learn-from links.** Each linked repo exists. Their contents were listed, not read in full. No Nord or Tokyo Night port was found for most command-line tools, and none of the five has a port for nano, less (beyond Dracula's man-pages), carapace, hexyl, zsh-autosuggestions, or zsh-history-substring-search.
- **Nothing was run.** All of this is from reading docs and source. No tool was installed or tested on either platform.
