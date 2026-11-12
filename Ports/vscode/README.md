# Hyaline for VS Code

**Tier:** 2 Flat
**Variants:** Hyaline Dark, Hyaline Light
**Tested with:** not yet tested on a real machine. Built from the official docs (see Sources).

| Hyaline Dark | Hyaline Light |
|---|---|
| ![Hyaline Dark](screenshots/dark.png) | ![Hyaline Light](screenshots/light.png) |

<!-- Screenshots are added by hand. Leave the paths in place. -->

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

---

## Reference

### Layout

VS Code cannot make its window translucent, so this is a Flat port: every surface uses its flat value.

- **Chrome** (`chrome_flat`): title bar, activity bar, status bar, and the empty part of the tab strip. They carry `text` and solid `accent` fills only.
- **Content** (`panel_flat`): the editor, side bar, bottom panel, tabs, and the hover, suggest, and peek widgets. Tabs and the side bar show colored git and problem labels, and widgets show code, so they stay on the panel where every color passes.
- **Raised** (`raised_flat`): inputs, dropdowns, menus, quick pick, and the command center.
- **Washes**: selections, find matches, word highlights, and diff and merge lines use a color role at the variant's wash alpha, so the code under them keeps its colors.

### Role mapping

<details>
<summary>Every color the theme sets</summary>

**Base**

| App setting | Role |
|---|---|
| `foreground` | `text` |
| `descriptionForeground` | `text_dim` |
| `disabledForeground` | `text_muted` |
| `errorForeground` | `red` |
| `focusBorder` | `accent` |
| `icon.foreground` | `text_dim` |
| `selection.background` | `accent` wash |
| `sash.hoverBorder` | `accent` |
| `textLink.foreground`, `textLink.activeForeground` | `accent` |
| `textPreformat.foreground` | `orange` |
| `textPreformat.background` | `raised_flat` |
| `textBlockQuote.background`, `textCodeBlock.background` | `raised_flat` |
| `textBlockQuote.border`, `textSeparator.foreground` | `line` |
| `scrollbar.shadow` | transparent |
| `scrollbarSlider.background` | `line` |
| `scrollbarSlider.hoverBackground` | `text_muted` |
| `scrollbarSlider.activeBackground` | `accent` |
| `progressBar.background` | `accent` |
| `badge.background` | `accent` |
| `badge.foreground` | `on_accent` |

**Title bar, activity bar, status bar (chrome)**

| App setting | Role |
|---|---|
| `titleBar.activeBackground`, `titleBar.inactiveBackground` | `chrome_flat` |
| `titleBar.activeForeground`, `titleBar.inactiveForeground` | `text` |
| `titleBar.border` | `line` |
| `window.activeBorder` | `accent` |
| `window.inactiveBorder` | `line` |
| `commandCenter.background`, `commandCenter.activeBackground` | `raised_flat` |
| `commandCenter.foreground`, `commandCenter.activeForeground` | `text` |
| `commandCenter.border`, `commandCenter.inactiveBorder` | `line` |
| `commandCenter.activeBorder` | `accent` |
| `menubar.selectionBackground` | `accent` |
| `menubar.selectionForeground` | `on_accent` |
| `activityBar.background`, `activityBarTop.background` | `chrome_flat` |
| `activityBar.foreground`, `activityBar.inactiveForeground`, `activityBarTop.foreground`, `activityBarTop.inactiveForeground` | `text` |
| `activityBar.activeBorder`, `activityBarTop.activeBorder`, `activityBar.dropBorder`, `activityBarTop.dropBorder` | `accent` |
| `activityBar.border` | `line` |
| `activityBarBadge.background` | `accent` |
| `activityBarBadge.foreground` | `on_accent` |
| `statusBar.background`, `statusBar.noFolderBackground` | `chrome_flat` |
| `statusBar.foreground`, `statusBar.noFolderForeground` | `text` |
| `statusBar.border` | `line` |
| `statusBar.focusBorder` | `accent` |
| `statusBar.debuggingBackground`, `statusBarItem.remoteBackground`, `statusBarItem.prominentBackground` | `accent` |
| `statusBar.debuggingForeground`, `statusBarItem.remoteForeground`, `statusBarItem.prominentForeground` | `on_accent` |
| `statusBarItem.hoverBackground`, `statusBarItem.activeBackground` | `raised_flat` |
| `statusBarItem.hoverForeground` | `text` |
| `statusBarItem.errorBackground` | `red` |
| `statusBarItem.errorForeground` | `on_accent` |
| `statusBarItem.warningBackground` | `yellow` |
| `statusBarItem.warningForeground` | `on_accent` |

**Side bar, panels, tabs (content)**

| App setting | Role |
|---|---|
| `sideBar.background`, `sideBarSectionHeader.background` | `panel_flat` |
| `sideBar.foreground`, `sideBarTitle.foreground`, `sideBarSectionHeader.foreground` | `text` |
| `sideBar.border`, `sideBarSectionHeader.border` | `line` |
| `sideBar.dropBackground` | `accent` wash |
| `editorGroupHeader.tabsBackground` | `chrome_flat` |
| `editorGroupHeader.noTabsBackground` | `panel_flat` |
| `editorGroupHeader.tabsBorder`, `editorGroup.border` | `line` |
| `editorGroup.dropBackground` | `accent` wash |
| `tab.activeBackground`, `tab.unfocusedActiveBackground`, `tab.inactiveBackground`, `tab.unfocusedInactiveBackground` | `panel_flat` |
| `tab.activeForeground`, `tab.unfocusedActiveForeground` | `text` |
| `tab.inactiveForeground`, `tab.unfocusedInactiveForeground` | `text_dim` |
| `tab.activeBorderTop` | `accent` |
| `tab.unfocusedActiveBorderTop`, `tab.border` | `line` |
| `tab.hoverBackground`, `tab.unfocusedHoverBackground` | `raised_flat` |
| `tab.activeModifiedBorder`, `tab.inactiveModifiedBorder` | `yellow` |
| `breadcrumb.background` | `panel_flat` |
| `breadcrumb.foreground` | `text_dim` |
| `breadcrumb.focusForeground`, `breadcrumb.activeSelectionForeground` | `text` |
| `breadcrumbPicker.background` | `raised_flat` |
| `panel.background` | `panel_flat` |
| `panel.border` | `line` |
| `panel.dropBorder` | `accent` |
| `panelTitle.activeForeground` | `text` |
| `panelTitle.inactiveForeground` | `text_dim` |
| `panelTitle.activeBorder` | `accent` |
| `panelSectionHeader.background` | `panel_flat` |
| `panelSectionHeader.foreground` | `text` |
| `panelSectionHeader.border` | `line` |

**Lists and trees**

| App setting | Role |
|---|---|
| `list.activeSelectionBackground`, `list.focusAndSelectionOutline` | `accent` |
| `list.activeSelectionForeground`, `list.activeSelectionIconForeground` | `on_accent` |
| `list.inactiveSelectionBackground`, `list.focusBackground`, `list.dropBackground` | `accent` wash |
| `list.inactiveSelectionForeground`, `list.focusForeground`, `list.hoverForeground` | `text` |
| `list.hoverBackground` | `raised_flat` |
| `list.focusOutline`, `list.inactiveFocusOutline`, `list.highlightForeground` | `accent` |
| `list.focusHighlightForeground` | `on_accent` |
| `list.errorForeground`, `list.invalidItemForeground` | `red` |
| `list.warningForeground` | `yellow` |
| `list.deemphasizedForeground` | `text_muted` |
| `tree.indentGuidesStroke` | `line` |
| `tree.inactiveIndentGuidesStroke` | `line` |

**Inputs, buttons, menus, quick pick**

| App setting | Role |
|---|---|
| `input.background`, `dropdown.background`, `dropdown.listBackground`, `checkbox.background` | `raised_flat` |
| `input.foreground`, `dropdown.foreground`, `checkbox.foreground` | `text` |
| `input.border`, `dropdown.border`, `checkbox.border` | `line` |
| `input.placeholderForeground` | `text_muted` |
| `inputOption.activeBackground` | `accent` wash |
| `inputOption.activeBorder` | `accent` |
| `inputOption.activeForeground` | `text` |
| `inputValidation.errorBackground` | `red` wash |
| `inputValidation.errorBorder` | `red` |
| `inputValidation.warningBackground` | `yellow` wash |
| `inputValidation.warningBorder` | `yellow` |
| `inputValidation.infoBackground` | `blue` wash |
| `inputValidation.infoBorder` | `blue` |
| `inputValidation.errorForeground`, `inputValidation.warningForeground`, `inputValidation.infoForeground` | `text` |
| `button.background`, `button.hoverBackground` | `accent` |
| `button.foreground` | `on_accent` |
| `button.separator` | `on_accent` |
| `button.secondaryBackground` | `raised_flat` |
| `button.secondaryHoverBackground` | `line` |
| `button.secondaryForeground` | `text` |
| `button.border` | `line` |
| `menu.background` | `raised_flat` |
| `menu.foreground` | `text` |
| `menu.selectionBackground` | `accent` |
| `menu.selectionForeground` | `on_accent` |
| `menu.separatorBackground`, `menu.border` | `line` |
| `quickInput.background`, `quickInputTitle.background` | `raised_flat` |
| `quickInput.foreground` | `text` |
| `quickInputList.focusBackground` | `accent` |
| `quickInputList.focusForeground`, `quickInputList.focusIconForeground` | `on_accent` |
| `pickerGroup.foreground` | `text_dim` |
| `pickerGroup.border` | `line` |
| `keybindingLabel.background` | `raised_flat` |
| `keybindingLabel.foreground` | `text` |
| `keybindingLabel.border`, `keybindingLabel.bottomBorder` | `line` |

**Notifications and widgets**

| App setting | Role |
|---|---|
| `notifications.background`, `notificationCenterHeader.background` | `panel_flat` |
| `notifications.foreground`, `notificationCenterHeader.foreground` | `text` |
| `notifications.border`, `notificationCenter.border`, `notificationToast.border` | `line` |
| `notificationLink.foreground` | `accent` |
| `notificationsErrorIcon.foreground` | `red` |
| `notificationsWarningIcon.foreground` | `yellow` |
| `notificationsInfoIcon.foreground` | `blue` |
| `editorWidget.background`, `editorHoverWidget.background`, `editorSuggestWidget.background`, `debugExceptionWidget.background` | `panel_flat` |
| `editorWidget.foreground`, `editorHoverWidget.foreground`, `editorSuggestWidget.foreground` | `text` |
| `editorWidget.border`, `editorHoverWidget.border`, `editorSuggestWidget.border`, `editorHoverWidget.statusBarBackground` | `line` |
| `editorWidget.resizeBorder` | `accent` |
| `debugExceptionWidget.border` | `red` |
| `editorSuggestWidget.selectedBackground` | `accent` |
| `editorSuggestWidget.selectedForeground`, `editorSuggestWidget.selectedIconForeground`, `editorSuggestWidget.focusHighlightForeground` | `on_accent` |
| `editorSuggestWidget.highlightForeground` | `accent` |
| `peekView.border` | `accent` |
| `peekViewEditor.background`, `peekViewEditorGutter.background`, `peekViewResult.background`, `peekViewTitle.background` | `panel_flat` |
| `peekViewTitleLabel.foreground`, `peekViewResult.fileForeground` | `text` |
| `peekViewTitleDescription.foreground`, `peekViewResult.lineForeground` | `text_dim` |
| `peekViewResult.selectionBackground` | `accent` |
| `peekViewResult.selectionForeground` | `on_accent` |
| `peekViewEditor.matchHighlightBackground`, `peekViewResult.matchHighlightBackground` | `accent` wash |
| `debugToolBar.background` | `raised_flat` |
| `debugToolBar.border` | `line` |

**Editor**

| App setting | Role |
|---|---|
| `editor.background`, `editorGutter.background`, `minimap.background` | `panel_flat` |
| `editor.foreground` | `text` |
| `editorLineNumber.foreground` | `text_muted` |
| `editorLineNumber.activeForeground` | `text` |
| `editorCursor.foreground` | `accent` |
| `editorCursor.background` | `on_accent` |
| `editor.selectionBackground`, `editor.inactiveSelectionBackground` | `accent` wash |
| `editor.selectionHighlightBackground`, `editor.wordHighlightBackground`, `editor.wordHighlightTextBackground` | `cyan` wash |
| `editor.wordHighlightStrongBackground` | `yellow` wash |
| `editor.findMatchBackground`, `editor.findMatchHighlightBackground`, `terminal.findMatchBackground`, `terminal.findMatchHighlightBackground` | `accent` wash |
| `editor.findMatchBorder`, `terminal.findMatchBorder` | `accent` |
| `editor.findRangeHighlightBackground`, `editor.rangeHighlightBackground`, `editor.hoverHighlightBackground` | `raised` with its alpha |
| `editor.lineHighlightBackground`, `editor.lineHighlightBorder` | `raised` with its alpha |
| `editorWhitespace.foreground`, `editorIndentGuide.background1`, `editorRuler.foreground` | `line` |
| `editorIndentGuide.activeBackground1` | `text_muted` |
| `editorBracketMatch.background` | `accent` wash |
| `editorBracketMatch.border` | `accent` |
| `editorBracketHighlight.foreground1`, `editorBracketHighlight.foreground2`, `editorBracketHighlight.foreground3`, `editorBracketHighlight.foreground4`, `editorBracketHighlight.foreground5`, `editorBracketHighlight.foreground6` | `text_dim` |
| `editorBracketHighlight.unexpectedBracket.foreground` | `red` |
| `editorLink.activeForeground` | `accent` |
| `editorCodeLens.foreground`, `editorInlayHint.foreground`, `editorGhostText.foreground` | `text_muted` |
| `editorInlayHint.background` | `raised` with its alpha |
| `editorError.foreground` | `red` |
| `editorWarning.foreground` | `yellow` |
| `editorInfo.foreground` | `blue` |
| `editorHint.foreground` | `text_muted` |
| `editorUnnecessaryCode.border` | `text_muted` |
| `editorGutter.addedBackground` | `green` |
| `editorGutter.modifiedBackground` | `yellow` |
| `editorGutter.deletedBackground` | `red` |
| `editorGutter.foldingControlForeground` | `text_dim` |
| `editorOverviewRuler.border` | `line` |
| `editorOverviewRuler.errorForeground` | `red` |
| `editorOverviewRuler.warningForeground` | `yellow` |
| `editorOverviewRuler.infoForeground` | `blue` |
| `editorOverviewRuler.addedForeground` | `green` |
| `editorOverviewRuler.modifiedForeground` | `yellow` |
| `editorOverviewRuler.deletedForeground` | `red` |
| `editorOverviewRuler.findMatchForeground`, `editorOverviewRuler.selectionHighlightForeground` | `accent` |
| `editorOverviewRuler.wordHighlightForeground` | `cyan` |
| `editorOverviewRuler.wordHighlightStrongForeground` | `yellow` |
| `minimap.findMatchHighlight`, `minimap.selectionHighlight` | `accent` |
| `minimap.errorHighlight` | `red` |
| `minimap.warningHighlight` | `yellow` |
| `minimapGutter.addedBackground` | `green` |
| `minimapGutter.modifiedBackground` | `yellow` |
| `minimapGutter.deletedBackground` | `red` |
| `editor.stackFrameHighlightBackground` | `yellow` wash |
| `editor.focusedStackFrameHighlightBackground` | `green` wash |
| `editorStickyScroll.background` | `panel_flat` |
| `editorStickyScroll.border` | `line` |
| `editorStickyScroll.shadow` | transparent |

**Diff and merge**

| App setting | Role |
|---|---|
| `diffEditor.insertedLineBackground` | `green` wash |
| `diffEditor.removedLineBackground` | `red` wash |
| `diffEditor.insertedTextBackground`, `diffEditor.removedTextBackground` | transparent |
| `diffEditor.insertedTextBorder` | `green` |
| `diffEditor.removedTextBorder` | `red` |
| `diffEditorGutter.insertedLineBackground`, `diffEditorOverview.insertedForeground` | `green` |
| `diffEditorGutter.removedLineBackground`, `diffEditorOverview.removedForeground` | `red` |
| `diffEditor.border` | `line` |
| `diffEditor.diagonalFill` | `line` |
| `merge.currentHeaderBackground`, `merge.currentContentBackground` | `green` wash |
| `merge.incomingHeaderBackground`, `merge.incomingContentBackground` | `blue` wash |
| `merge.commonHeaderBackground`, `merge.commonContentBackground` | `magenta` wash |
| `merge.border` | `line` |
| `editorOverviewRuler.currentContentForeground` | `green` |
| `editorOverviewRuler.incomingContentForeground` | `blue` |
| `editorOverviewRuler.commonContentForeground` | `magenta` |

**Git, problems, testing, debug**

| App setting | Role |
|---|---|
| `gitDecoration.addedResourceForeground`, `gitDecoration.untrackedResourceForeground` | `green` |
| `gitDecoration.modifiedResourceForeground`, `gitDecoration.stageModifiedResourceForeground`, `gitDecoration.renamedResourceForeground` | `yellow` |
| `gitDecoration.deletedResourceForeground`, `gitDecoration.stageDeletedResourceForeground`, `gitDecoration.conflictingResourceForeground` | `red` |
| `gitDecoration.ignoredResourceForeground` | `text_muted` |
| `gitDecoration.submoduleResourceForeground` | `cyan` |
| `problemsErrorIcon.foreground` | `red` |
| `problemsWarningIcon.foreground` | `yellow` |
| `problemsInfoIcon.foreground` | `blue` |
| `testing.iconPassed`, `testing.runAction` | `green` |
| `testing.iconFailed`, `testing.iconErrored` | `red` |
| `testing.iconQueued` | `magenta` |
| `testing.iconSkipped`, `testing.iconUnset` | `text_muted` |
| `debugIcon.breakpointForeground` | `red` |
| `debugIcon.breakpointDisabledForeground`, `debugIcon.breakpointUnverifiedForeground` | `text_muted` |
| `debugIcon.breakpointCurrentStackframeForeground` | `yellow` |
| `debugIcon.startForeground`, `debugIcon.continueForeground` | `green` |
| `debugIcon.stopForeground`, `debugIcon.disconnectForeground` | `red` |
| `debugIcon.pauseForeground`, `debugIcon.restartForeground`, `debugIcon.stepOverForeground`, `debugIcon.stepIntoForeground`, `debugIcon.stepOutForeground`, `debugIcon.stepBackForeground` | `blue` |
| `debugConsole.infoForeground` | `blue` |
| `debugConsole.warningForeground` | `yellow` |
| `debugConsole.errorForeground` | `red` |
| `debugConsole.sourceForeground` | `text_dim` |
| `debugConsoleInputIcon.foreground` | `accent` |
| `settings.headerForeground` | `text` |
| `settings.modifiedItemIndicator` | `yellow` |
| `charts.foreground` | `text` |
| `charts.lines` | `line` |
| `charts.red` | `red` |
| `charts.green` | `green` |
| `charts.yellow` | `yellow` |
| `charts.blue` | `blue` |
| `charts.purple` | `magenta` |
| `charts.orange` | `orange` |

**Symbol icons**

| App setting | Role |
|---|---|
| `symbolIcon.functionForeground`, `symbolIcon.methodForeground`, `symbolIcon.constructorForeground`, `symbolIcon.propertyForeground`, `symbolIcon.fieldForeground`, `symbolIcon.keyForeground` | `blue` |
| `symbolIcon.stringForeground` | `green` |
| `symbolIcon.numberForeground`, `symbolIcon.unitForeground` | `orange` |
| `symbolIcon.keywordForeground`, `symbolIcon.constantForeground`, `symbolIcon.booleanForeground`, `symbolIcon.nullForeground`, `symbolIcon.enumeratorMemberForeground` | `magenta` |
| `symbolIcon.classForeground`, `symbolIcon.interfaceForeground`, `symbolIcon.structForeground`, `symbolIcon.enumeratorForeground`, `symbolIcon.typeParameterForeground`, `symbolIcon.moduleForeground`, `symbolIcon.namespaceForeground`, `symbolIcon.packageForeground`, `symbolIcon.referenceForeground` | `cyan` |
| `symbolIcon.eventForeground` | `yellow` |
| `symbolIcon.variableForeground` | `text` |
| `symbolIcon.fileForeground`, `symbolIcon.folderForeground`, `symbolIcon.operatorForeground`, `symbolIcon.snippetForeground`, `symbolIcon.textForeground`, `symbolIcon.arrayForeground`, `symbolIcon.objectForeground`, `symbolIcon.colorForeground` | `text_dim` |

**Terminal**

| App setting | Role |
|---|---|
| `terminal.background` | `panel_flat` |
| `terminal.foreground` | `text` |
| `terminal.border` | `line` |
| `terminalCursor.foreground` | `accent` |
| `terminalCursor.background` | `on_accent` |
| `terminal.selectionBackground` | `accent` |
| `terminal.selectionForeground` | `on_accent` |
| `terminal.inactiveSelectionBackground` | `accent` wash |
| `terminalCommandDecoration.successBackground` | `green` |
| `terminalCommandDecoration.errorBackground` | `red` |
| `terminalCommandDecoration.defaultBackground` | `text_muted` |
| `terminal.ansiBlack` | terminal `black` slot (see below) |
| `terminal.ansiRed` | terminal `red` slot (see below) |
| `terminal.ansiGreen` | terminal `green` slot (see below) |
| `terminal.ansiYellow` | terminal `yellow` slot (see below) |
| `terminal.ansiBlue` | terminal `blue` slot (see below) |
| `terminal.ansiMagenta` | terminal `magenta` slot (see below) |
| `terminal.ansiCyan` | terminal `cyan` slot (see below) |
| `terminal.ansiWhite` | terminal `white` slot (see below) |
| `terminal.ansiBrightBlack` | terminal `bright_black` slot (see below) |
| `terminal.ansiBrightRed` | terminal `bright_red` slot (see below) |
| `terminal.ansiBrightGreen` | terminal `bright_green` slot (see below) |
| `terminal.ansiBrightYellow` | terminal `bright_yellow` slot (see below) |
| `terminal.ansiBrightBlue` | terminal `bright_blue` slot (see below) |
| `terminal.ansiBrightMagenta` | terminal `bright_magenta` slot (see below) |
| `terminal.ansiBrightCyan` | terminal `bright_cyan` slot (see below) |
| `terminal.ansiBrightWhite` | terminal `bright_white` slot (see below) |

**Syntax (TextMate scopes and semantic tokens)**

| Token | Role |
|---|---|
| Variables and plain text | `text` |
| Punctuation and operators | `text_dim` |
| Keywords, booleans, constants | `magenta` |
| Keys, properties, functions | `blue` |
| Types, references, anchors | `cyan` |
| Tags, annotations, decorators | `yellow` |
| Numbers and literals | `orange` |
| Strings | `green` |
| Comments | `text_muted` |
| Errors and invalid | `red` |
| Diff: ranges | `blue` |
| Diff: added | `green` |
| Diff: removed | `red` |
| Diff: changed | `yellow` |

**Terminal**

| Slot | Dark | Light |
|---|---|---|
| black | `raised_flat` | `text` |
| red, green, yellow, blue, cyan (and bright) | their namesake role | their namesake role |
| magenta, bright magenta | `magenta` | `magenta` |
| bright black | `text_muted` | `text_muted` |
| white | `text_dim` | `line` |
| bright white | `text` | `raised_flat` |

Semantic tokens follow the same table: types, classes, and namespaces are `cyan`, functions, methods, and properties `blue`, enum members, keywords, and macros `magenta`, decorators and events `yellow`, parameters and variables `text`.

</details>

### Known gaps

- **No glass.** VS Code cannot make its window translucent.
- **Selected text keeps its syntax colors.** VS Code only allows a selected text color in high contrast themes, so the selection is an `accent` wash instead of a solid fill.
- **Changed characters inside a diff line** get a thin `green` or `red` border instead of a stronger tint. Two washes on top of each other would drop text below the contrast floor.
- **Rainbow brackets are off.** All bracket pair colors are `text_dim`, since brackets are punctuation. Turn colorization off entirely with `"editor.bracketPairColorization.enabled": false` if you prefer.
- **Button hover** does not change color. The palette has one accent, with no hover shade.
- **Shadows** under widgets and menus use VS Code's default shadow.
- **Settings not listed above** keep VS Code's default for the base theme (Dark Modern or Light Modern). That covers newer or rarely seen parts, such as the notebook editor, chat, and the welcome page.
- **Not tested on a real machine yet.** See [Still to do](#still-to-do).

### Still to do

Before this port counts as finished:

1. **Test the VSIX install.** Follow [Install](#install) on Windows from a clean VS Code. Note any question `vsce` asks and anything that differs from the steps.
2. **Test the folder install.** Follow [Install without Node.js](#install-without-nodejs). If VS Code ignores the copied folders, remove that section and say so under Troubleshooting.
3. **Check both variants.** Switch with **Ctrl+K**, **Ctrl+T**. Open a diff, select code, and run a search. Check that selected and highlighted code is readable, especially yellow and cyan in Light.
4. **Check following Windows.** Turn on the settings in [Switch between Dark and Light](#switch-between-dark-and-light) and change the Windows mode.
5. **Fill in "Tested with"** at the top with the VS Code version and OS.
6. **Add screenshots.** Save one per variant as `screenshots/dark.png` and `screenshots/light.png` in this folder.
7. **Set the publisher.** `template/package.json` uses `hyaline` as a placeholder. Replace it with the real Marketplace publisher ID once one exists, then rebuild.
8. **Publish to the Marketplace.** Only after steps 1 to 7. Tracked in [issue #14](https://github.com/mookeyj79/Hyaline/issues/14).

### Sources and credits

- [Color Theme guide](https://code.visualstudio.com/api/extension-guides/color-theme): theme file, `colors`, `tokenColors`, semantic highlighting
- [Theme Color reference](https://code.visualstudio.com/api/references/theme-color): every workbench color key (all keys used here were checked against it)
- [Contribution points](https://code.visualstudio.com/api/references/contribution-points#contributes.themes): `contributes.themes`, `label`, `uiTheme`, `path`
- [Publishing extensions](https://code.visualstudio.com/api/working-with-extensions/publishing-extension): `vsce package`, required `publisher` and `engines`, extensions folder
- [Extension Marketplace](https://code.visualstudio.com/docs/configure/extensions/extension-marketplace): **Install from VSIX**, `code --install-extension`, extensions folder per OS
- [Themes](https://code.visualstudio.com/docs/configure/themes): **Ctrl+K Ctrl+T**, following the OS color scheme
- [Diff editor color defaults](https://github.com/microsoft/vscode/blob/main/src/vs/platform/theme/common/colors/editorColors.ts): diff line and text colors default to VS Code tints, so both are set
- Ports studied: [Catppuccin for VS Code](https://github.com/catppuccin/vscode) and [Nord for VS Code](https://github.com/nordtheme/visual-studio-code), both MIT. Method only: which workbench keys to cover, `semanticHighlighting`, and the recommended `terminal.integrated.minimumContrastRatio` and `window.titleBarStyle` settings. No files or colors reused.
