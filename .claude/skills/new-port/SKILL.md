---
name: new-port
description: Create a new port of this repo's theme for an app, tool, OS, or website. Use when asked to "make a theme for X", "create a Windows theme", "port the theme to X", or "add X support".
argument-hint: [app-name]
---

# New port

Create a port of the theme for: $ARGUMENTS

A port is done when it builds from the palette, passes the checks, and has a README someone else could install from. Follow the steps in order.

## 1. Load the rules

- Read `PHILOSOPHY.md` and `palette/palette.json`.
- If the palette or build scripts are missing, stop and follow the Bootstrap section in `CLAUDE.md`.
- Look at one existing port in `Ports/` for conventions, if any exist.

## 2. Pin down the target

- Pick the folder name (`<app_name>`): lowercase, hyphenated, the app's common name (`windows-terminal`, `typora`, `vscode`).
- If `Ports/<app_name>/` exists, this is an update, not a new port. Say so and continue as an update.
- If the request is ambiguous, ask one question before going further. "Windows theme" is the classic case: it could mean the OS theme, Windows Terminal, or both. An OS theme usually controls far less than people expect, so say what it can and cannot change.

## 3. Research how the app is themed

Search the web and read the app's official documentation. Do not rely on memory for file formats or setting names. Find:

- **Format**: CSS, JSON, XML, INI, a settings UI, a browser user style, something else
- **Location**: where the theme file goes on Windows first, then other platforms
- **Reach**: what can be colored (background, text, syntax, UI chrome, status colors)
- **Modes**: does it support light and dark, and can it follow the OS setting
- **Translucency**: can the window or panels be transparent or blurred
- **Versioning**: does the format differ between app versions

Then look at how other themes ported to this app. This is expected, not optional. Find the Catppuccin port first (it has the widest coverage), then Nord, Dracula, or Rosé Pine. From them, learn:

- The file layout and install method that works in practice
- Which settings are worth theming and which are ignored by the app
- How they ship light and dark together
- Workarounds for things the app does not officially support

Take the method, not the colors. Every color still comes from the palette, and every slot still maps to a role per PHILOSOPHY.md. If you reuse more than the basic structure of someone's port, check its license and credit it in the README.

Keep the source URLs, including the ports you studied. They go in the README.

If the app cannot be themed at all, say so and stop. Do not ship a workaround that patches app files unless the user asks for it.

## 4. Choose the tier

Per PHILOSOPHY.md:

- **Tier 1, Full glass**: full palette plus translucency and blur
- **Tier 2, Flat**: full palette with `panel_flat` and `raised_flat`
- **Tier 3, Accent**: only background, accent, and status colors

Tell the user the tier and the known gaps in two or three lines, then carry on. Only wait for an answer if the port would be Tier 3 or worse than they likely expect.

## 5. Map the app's slots to roles

List every color slot the app exposes and assign each one a role. Write this as a table. It goes in the README.

- Surfaces: `panel` or `panel_flat` for the main area, `raised` or `raised_flat` for bars, tabs, cards, inputs
- Text: `text` for content, `text_dim` for supporting, `text_muted` for comments and metadata
- Focus, selection, cursor, links, primary buttons: `accent`, with `on_accent` for text on top of it
- State: `red` failure, `green` success, `yellow` change or warning, `blue` info or in progress
- Syntax: follow the syntax mapping table in PHILOSOPHY.md exactly
- Terminal ANSI: black and white map to neutral roles, the six colors map to their namesakes, purple maps to `magenta`

If a slot has no fitting role, use the closest one. If nothing is close, stop and propose a palette change. Never invent a color.

## 6. Write the template

- Put files in `Ports/<app_name>/template/`, named the way the app expects.
- Use `{{role}}` placeholders for every color. See the placeholder table in `CLAUDE.md`.
- One template should serve both variants. Split only if the app needs structurally different files per mode.
- Use `{{meta.name}}` and `{{variant.name}}` for display names inside the file.
- No raw color values, including in comments.

## 7. Build and check

```
pwsh build/build.ps1 -Port <app_name>
pwsh build/check.ps1
```

Then verify by hand:

- The generated files are valid for their format (JSON parses, CSS has no syntax errors, XML is well formed).
- Both `dist/dark/` and `dist/light/` exist, unless the app is single mode.
- Light variant: yellow and cyan text is still readable on the panel.

Fix the template and rebuild until everything passes. Never edit `dist/`.

## 8. Write the install guide

Copy `port-readme-template.md` from this skill's folder to `Ports/<app_name>/README.md` and fill in every section.

The README is first and foremost a step-by-step install guide. Write it for someone who has never themed this app:

- Number every step. One action per step.
- Use real paths, real menu names, and real setting names, taken from the docs you read in step 3. Windows first.
- Say what the reader should see when a step worked.
- Include how to switch variants and how to uninstall.
- Keep reference material (role mapping, known gaps, sources) below the guide.

## 9. Finish

- Add the port to the list in the root `README.md` with its tier.
- Commit on a branch named `port/<app_name>`.
- Report back in a few lines: tier, what is covered, what is not, and what the user needs to do (install steps live in the README, screenshots are theirs to add).

Do not install the theme on the user's machine unless they ask.
