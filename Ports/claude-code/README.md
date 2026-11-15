# Hyaline for Claude Code

**Tier:** 2 Flat
**Variants:** Hyaline Dark, Hyaline Light
**Tested with:** Not tested yet

The port is a pair of Claude Code custom themes, one file per variant. It covers the Claude Code CLI in a terminal: the prompt box, dialogs, status colors, diffs, mode indicators, and message backgrounds.

Claude Code draws on your terminal's background, so it has no surface of its own to make glass. The glass comes from the terminal. Pair this port with a Hyaline terminal port, such as [Windows Terminal](../windows-terminal/README.md), on the same variant. The diff and highlight colors are made for the Hyaline terminal background, so they look right only on a Hyaline terminal.

## Before you start

- Claude Code with custom themes. Run `/theme` in Claude Code: if the list ends with **New custom theme…**, you are set. If not, run `claude update` first.
- A terminal that shows 24-bit color. Windows Terminal, iTerm2, and most modern terminals do.
- A Hyaline terminal port installed, on the same variant you plan to use here.

## Install

Claude Code reads custom themes from the `themes` folder inside its config folder.

| OS | Folder |
|---|---|
| Windows | `%USERPROFILE%\.claude\themes` |
| macOS, Linux | `~/.claude/themes` |

If you set the `CLAUDE_CONFIG_DIR` environment variable, use the `themes` folder inside that folder instead.

1. Download or clone this repo.
2. Open your `.claude` folder. On Windows, open File Explorer, type `%USERPROFILE%\.claude` in the address bar, and press **Enter**.
3. If there is no `themes` folder, create one. On Windows you can also run `mkdir -Force ~/.claude/themes` in PowerShell.
4. Copy `Ports/claude-code/dist/dark/hyaline-dark.json` into `themes`.
5. Copy `Ports/claude-code/dist/light/hyaline-light.json` into `themes` too. With both installed, switching is one menu pick.
6. If you created the `themes` folder in step 3, quit any running Claude Code session and start it again. Claude Code watches the folder only if it existed at startup. After that, changes apply without a restart.
7. In Claude Code, run `/theme`.
8. Pick **Hyaline Dark** (or **Hyaline Light**) and press **Enter**. The prompt box border turns a soft gray and the spinner turns Hyaline blue.

Claude Code saves the choice as `"theme": "custom:hyaline-dark"` in `~/.claude/settings.json`. You can also set that line by hand instead of steps 7 and 8.

Files to use:

- Hyaline Dark: `dist/dark/hyaline-dark.json`
- Hyaline Light: `dist/light/hyaline-light.json`

## Set the font

Hyaline uses [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads). If it is not installed yet, follow [Font](../../README.md#font) in the main README.

Claude Code cannot set a font. It uses your terminal's font, so set **FiraCode Nerd Font Mono** in the terminal. The Windows Terminal port already does this.

## Check that it worked

1. Run `/theme`. **Hyaline Dark** (or Light) is marked as the current theme.
2. Ask Claude to edit a file. Added lines sit on a faint green wash, removed lines on a faint red wash, and the text stays readable on both.
3. Press **Shift+Tab** to cycle modes. Plan mode shows in Hyaline magenta, accept-edits mode in yellow.

## Switch between Dark and Light

1. Switch your terminal to the same variant first, so the background matches.
2. In Claude Code, run `/theme`.
3. Pick **Hyaline Dark** or **Hyaline Light** and press **Enter**.

Claude Code cannot follow your OS light or dark setting with a custom theme. Its **auto** option switches only between the built-in themes.

## Uninstall

1. In Claude Code, run `/theme`.
2. Pick **Dark** (or any built-in theme) and press **Enter**.
3. Delete `hyaline-dark.json` and `hyaline-light.json` from the `themes` folder.

## Troubleshooting

- **Hyaline is not in the `/theme` list**: the `themes` folder did not exist when Claude Code started. Restart Claude Code. Also check that the files end in `.json` and sit directly in `themes`, not in a subfolder.
- **There is no New custom theme… entry in `/theme`**: your Claude Code is too old for custom themes. Run `claude update`.
- **Diff lines look muddy or barely tinted**: the terminal is not on a Hyaline color scheme, or it is on the other variant. Switch the terminal to the matching Hyaline scheme.
- **Colors look dull or slightly off**: the terminal is not showing 24-bit color. On Windows, use Windows Terminal rather than the old console window.
- **The theme is ignored after you set it in `settings.json`**: a project's `.claude/settings.json` or `.claude/settings.local.json` sets `theme` too, and wins. Run `/status` to see which files loaded.
- **Code in answers and diffs keeps Claude Code's own colors**: expected, see [Known limits](#known-limits).

## Known limits

- **No glass of its own.** Claude Code draws on the terminal's background, so the glass comes from your terminal.
- **Code colors are not themeable.** Code blocks, diffs, and file previews use Claude Code's built-in highlighter, which custom themes cannot reach. To drop its colors, set `"syntaxHighlightingDisabled": true` in `~/.claude/settings.json`.
- **Diff and highlight colors need a Hyaline terminal.** On another background they look off.
- **No word-level diff emphasis.** The changed words in a line are tinted the same as the rest of the line.
- **No shimmer and no rainbow.** Spinner shimmers and the `ultrathink` rainbow are flattened to one color each.
- **Cannot follow the OS light or dark setting.** Switch with `/theme`.
- **Some colors stay at Claude Code's defaults**, such as the onboarding mascot.
- **The user message card is faint in Light.** It is only a shade lighter than the background.
- **The desktop app, claude.ai, and the VS Code chat panel are not covered.** The desktop app and claude.ai pick from a fixed list of code themes. The VS Code panel follows VS Code's theme, so use the [VS Code port](../vscode/README.md) there.

## Sources

- [Claude Code terminal configuration, Create a custom theme](https://code.claude.com/docs/en/terminal-config#create-a-custom-theme)
- [Claude Code settings reference, `theme`](https://code.claude.com/docs/en/settings-reference#theme)
- [Claude Code settings reference, `syntaxHighlightingDisabled`](https://code.claude.com/docs/en/settings-reference#syntaxhighlightingdisabled)
- [Claude Code settings](https://code.claude.com/docs/en/settings)
- [Claude Code plugin components, Themes](https://code.claude.com/docs/en/plugins/components#themes-and-output-styles)
