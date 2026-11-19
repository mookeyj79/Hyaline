# Hyaline for VS Code

**Tier:** 2 Flat\
**Variants:** Hyaline Dark, Hyaline Light\
**Tested with:** Not tested yet

Each variant is its own small VS Code extension: `dist/dark/` is **Hyaline Dark** and `dist/light/` is **Hyaline Light**. Install both, then pick one or let VS Code follow Windows.

## Before you start

- VS Code 1.80 or later. Check it in **Help** > **About**.
- [Node.js](https://nodejs.org) (the LTS version) to package the extensions. It is only needed during install. If you cannot install Node.js, see [Install without Node.js](#install-without-nodejs).

## Install

1. Download or clone this repo.
2. Open a terminal (PowerShell on Windows) in the repo folder.
3. Go to the Dark extension:

   ```
   cd Ports/vscode/dist/dark
   ```

4. Package it:

   ```
   npx @vscode/vsce package
   ```

   If `npx` asks to install `@vscode/vsce`, answer `y`. When it finishes, the folder holds a file named `hyaline-dark-<version>.vsix`.
5. Do the same for Light:

   ```
   cd ../light
   npx @vscode/vsce package
   ```

   This makes `hyaline-light-<version>.vsix`.
6. Open VS Code. Press **Ctrl+Shift+P**, type `Extensions: Install from VSIX`, and press **Enter**.
7. Pick `Ports/vscode/dist/dark/hyaline-dark-<version>.vsix` and click **Install**. VS Code shows "Completed installing extension".
8. Repeat steps 6 and 7 with `Ports/vscode/dist/light/hyaline-light-<version>.vsix`.
9. Press **Ctrl+K**, then **Ctrl+T** to open the color theme list. Pick **Hyaline Dark** or **Hyaline Light**.

Steps 6 to 8 can also be done from a terminal: `code --install-extension hyaline-dark-<version>.vsix`.

Files to use:

- Hyaline Dark: `dist/dark/` (`package.json`, `themes/hyaline-dark-color-theme.json`, `LICENSE`)
- Hyaline Light: `dist/light/` (`package.json`, `themes/hyaline-light-color-theme.json`, `LICENSE`)

### Install without Node.js

VS Code's docs describe loading an extension by copying it into the extensions folder. Newer versions keep a list of installed extensions and may ignore folders copied by hand, so use this only if the steps above are not an option.

1. Close every VS Code window.
2. Open File Explorer, click the address bar, type `%USERPROFILE%\.vscode\extensions`, and press **Enter**. On macOS and Linux the folder is `~/.vscode/extensions`.
3. Copy the folder `Ports/vscode/dist/dark` into it and rename the copy to `hyaline.hyaline-dark`.
4. Copy `Ports/vscode/dist/light` the same way and rename it to `hyaline.hyaline-light`.
5. Open VS Code and continue with step 9 above.

If the themes are not in the list, use the VSIX steps instead.

## Set the font

Hyaline uses [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads). If it is not installed yet, follow [Font](../../README.md#font) in the main README.

1. Press **Ctrl+Shift+P**, type `Preferences: Open User Settings (JSON)`, and press **Enter**.
2. Add these lines inside the outer braces:

   ```json
   "editor.fontFamily": "'FiraCode Nerd Font Mono'",
   "editor.fontLigatures": true,
   "terminal.integrated.fontFamily": "'FiraCode Nerd Font Mono'"
   ```

3. Save. The editor and the terminal switch font right away.

To turn ligatures off, set `"editor.fontLigatures": false`.

## Check that it worked

The editor is a soft gray (Dark) or frost white (Light), and the title bar, activity bar, and status bar are a slightly different gray around it. Select some code: the selection is a light blue tint and the code keeps its colors.

## Switch between Dark and Light

To switch by hand, press **Ctrl+K**, then **Ctrl+T**, and pick the other variant.

To follow the Windows light or dark setting (also works on macOS):

1. Open your user `settings.json` (step 1 of [Set the font](#set-the-font)).
2. Add:

   ```json
   "window.autoDetectColorScheme": true,
   "workbench.preferredDarkColorTheme": "Hyaline Dark",
   "workbench.preferredLightColorTheme": "Hyaline Light"
   ```

3. Save. VS Code now switches when you change Windows **Settings** > **Personalization** > **Colors** > **Choose your mode**.

## Uninstall

1. Open the Extensions view with **Ctrl+Shift+X**.
2. Search for `@installed Hyaline`.
3. Click the gear on **Hyaline Dark** and choose **Uninstall**. Do the same for **Hyaline Light**.
4. Press **Ctrl+K**, then **Ctrl+T**, and pick another theme, such as **Dark Modern**.
5. Remove the `workbench.preferredDarkColorTheme`, `workbench.preferredLightColorTheme`, and font lines from `settings.json` if you added them.

If you used the folder install, close VS Code and delete the two `hyaline.hyaline-*` folders from the extensions folder instead.

## Troubleshooting

- **`npx` is not recognized**: Node.js is not installed or the terminal was opened before installing it. Install Node.js LTS and open a new terminal.
- **`vsce` stops and asks a question**: answer `y`. It may ask about a missing README in the extension folder.
- **Hyaline is not in the theme list**: reload with **Ctrl+Shift+P** > `Developer: Reload Window`. If you used the folder install, use the VSIX steps.
- **Terminal colors look a little off**: VS Code adjusts terminal text it thinks is hard to read. Set `"terminal.integrated.minimumContrastRatio": 1` to show Hyaline's colors as they are.
- **The title bar is the Windows default**: set `"window.titleBarStyle": "custom"`. On Windows this is the default.
- **Some colors look like VS Code's own theme**: a setting in `workbench.colorCustomizations` or `editor.tokenColorCustomizations` overrides Hyaline. Remove it, or check for another theme extension forcing colors.

## Known limits

- **No glass.** VS Code cannot make its window translucent.
- **Selected text keeps its syntax colors.** The selection is a light blue tint, not a solid block with plain text.
- **Changed characters inside a diff line** get a thin green or red outline, not a stronger highlight.
- **Rainbow brackets are off.** All brackets are the same soft gray. To turn bracket colors off entirely, set `"editor.bracketPairColorization.enabled": false`.
- **Buttons do not change color on hover.**
- **Shadows** under popups and menus are VS Code's default shadow.
- **Some newer or rarely seen parts**, such as the notebook editor, chat, and the welcome page, use VS Code's own Dark Modern or Light Modern colors.

## Sources

- [Color Theme guide](https://code.visualstudio.com/api/extension-guides/color-theme): theme file, `colors`, `tokenColors`, semantic highlighting
- [Theme Color reference](https://code.visualstudio.com/api/references/theme-color): every workbench color key
- [Contribution points](https://code.visualstudio.com/api/references/contribution-points#contributes.themes): `contributes.themes`, `label`, `uiTheme`, `path`
- [Publishing extensions](https://code.visualstudio.com/api/working-with-extensions/publishing-extension): `vsce package`, required `publisher` and `engines`, extensions folder
- [Extension Marketplace](https://code.visualstudio.com/docs/configure/extensions/extension-marketplace): **Install from VSIX**, `code --install-extension`, extensions folder per OS
- [Themes](https://code.visualstudio.com/docs/configure/themes): **Ctrl+K Ctrl+T**, following the OS color scheme
