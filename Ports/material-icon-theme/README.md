# Hyaline for Material Icon Theme

**Tier:** 3 Minimal
**Variants:** Hyaline Dark, Hyaline Light
**Tested with:** Not tested yet

[Material Icon Theme](https://marketplace.visualstudio.com/items?itemName=PKief.material-icon-theme) is a file icon theme for VS Code. Most of its icons are fixed logos and cannot be recolored. It does let you set three colors: the default folder icon, the root folder icon, and the default file icon. This port sets those three to Hyaline's text colors, so plain folders and files sit quietly in the explorer and only the language icons stand out.

Use it together with the [VS Code port](../vscode/README.md), on the same variant.

## Before you start

- VS Code with the Hyaline color theme installed. See the [VS Code port](../vscode/README.md).
- Material Icon Theme installed. In VS Code, press **Ctrl+Shift+X**, search for `Material Icon Theme` (publisher: Philipp Kief), and click **Install**.

## Install

1. In VS Code, press **Ctrl+Shift+P**, type `Preferences: Open User Settings (JSON)`, and press **Enter**. On macOS, use **Cmd+Shift+P**.
2. Open `Ports/material-icon-theme/dist/dark/material-icon-theme-dark.json` from this repo. For Light, open `Ports/material-icon-theme/dist/light/material-icon-theme-light.json` instead.
3. Copy the four lines inside its braces.
4. Paste them inside the outer braces of your `settings.json`. Add a comma after the line above them if it does not end with one. If your file already has any of these four settings, delete the old lines.
5. Save the file. VS Code asks to reload or reloads the icons by itself after a few seconds.

Files to use:

- Hyaline Dark: `dist/dark/material-icon-theme-dark.json`
- Hyaline Light: `dist/light/material-icon-theme-light.json`

## Set the font

Hyaline uses [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads). Material Icon Theme has no font of its own. Set the font in VS Code itself, as described in [Set the font](../vscode/README.md#set-the-font) in the VS Code port.

## Check that it worked

Open the Explorer (**Ctrl+Shift+E**). Plain folders and files without a language icon are a soft gray that matches the explorer text, and the top folder of your workspace is a little brighter. Language icons such as JavaScript or Markdown keep their own colors.

## Switch between Dark and Light

Material Icon Theme cannot follow your OS light or dark setting, and VS Code cannot change extension settings per color theme. Switching is a manual step:

1. Switch the VS Code color theme to the other Hyaline variant.
2. Open your user `settings.json` (step 1 of [Install](#install)).
3. Replace the three `material-icon-theme.*.color` lines with the ones from the other variant's file.
4. Save.

If you use `window.autoDetectColorScheme` to follow the OS, the icon colors do not follow along. Pick the variant you use most.

## Optional: calmer folders

By default, Material Icon Theme gives many folders their own colored icon (`src`, `test`, `docs`, and so on). Those colors come from the extension, not from Hyaline. To make every folder use the Hyaline folder color, also add:

```json
"material-icon-theme.folders.theme": "classic"
```

Set it back to `"specific"` to get the colored folder icons back.

## Uninstall

1. Open your user `settings.json` (step 1 of [Install](#install)).
2. Delete the `material-icon-theme.folders.color`, `material-icon-theme.rootFolders.color`, and `material-icon-theme.files.color` lines, plus `material-icon-theme.folders.theme` if you added it.
3. Save. The icons go back to the extension's default gray.

To stop using the icon theme altogether, also delete the `workbench.iconTheme` line, or press **Ctrl+Shift+P**, run `Preferences: File Icon Theme`, and pick another one.

## Troubleshooting

- **Icons did not change color**: run **Ctrl+Shift+P** > `Developer: Reload Window`. Check that the explorer's icon theme is Material Icon Theme (`Preferences: File Icon Theme`).
- **VS Code shows a red squiggle on a color line**: the value must be a six digit hex color with `#`. Copy it again from the `dist/` file.
- **Only some folders changed**: that is expected. Folders with their own icon keep the extension's colors. See [Optional: calmer folders](#optional-calmer-folders).

## Known limits

- Language, file type, and specific folder icons keep the extension's own colors. Only plain folders, the root folder, and plain files change.
- The icon colors do not switch when VS Code switches between Dark and Light. Switching is a manual edit.
- No glass. Icons have no background of their own. The explorer background comes from the VS Code port.

## Sources

- [Material Icon Theme README](https://github.com/material-extensions/vscode-material-icon-theme): settings and examples.
- [Material Icon Theme `package.json`](https://github.com/material-extensions/vscode-material-icon-theme/blob/main/package.json): exact setting names, defaults, and the hex color format.
