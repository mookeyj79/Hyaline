# Material Icon Theme: role mapping

For maintainers. The install guide is [README.md](README.md).

## Role mapping

| App setting | Role | Why |
|---|---|---|
| `material-icon-theme.folders.color` | `text_dim` | The same role as `icon.foreground` in the VS Code port, so folders match VS Code's own icons |
| `material-icon-theme.rootFolders.color` | `text` | Primary text, so the workspace root stands above other folders |
| `material-icon-theme.files.color` | `text_muted` | Meets the 3:1 floor for icons and keeps plain files quiet |

Accent is not used: in Hyaline it means "you are here", and the explorer selection already shows that.

## Gaps and trade-offs

- Language, file type, and specific folder icons are fixed images. Their colors come from the extension and cannot be mapped to roles. This is why the port is Tier 3.
- One set of colors at a time. The settings are global, and VS Code cannot change extension settings per color theme, so they do not switch with the variant.
- `material-icon-theme.opacity` and `material-icon-theme.saturation` are left at their defaults. Lowering them would fade every icon, which hurts readability.
- No glass. Icons have no surface of their own.

## Research

- Built from the extension's `package.json` and source at version 5.40.0.
- [`folderGenerator.ts`](https://github.com/material-extensions/vscode-material-icon-theme/blob/main/src/core/generator/folderGenerator.ts) and [`fileGenerator.ts`](https://github.com/material-extensions/vscode-material-icon-theme/blob/main/src/core/generator/fileGenerator.ts): confirm the color settings only recolor the default folder, root folder, and file icons.
- No Catppuccin, Nord, Dracula, or Rosé Pine port of these settings was found. Catppuccin ships its own icon theme instead ([catppuccin/vscode-icons](https://github.com/catppuccin/vscode-icons)).
