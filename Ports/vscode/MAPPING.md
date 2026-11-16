# VS Code: role mapping

For maintainers. The install guide is [README.md](README.md).

## Layout

VS Code cannot make its window translucent, so this is a Flat port: every surface uses its flat value.

- **Chrome** (`chrome_flat`): title bar, activity bar, status bar, and the empty part of the tab strip. They carry `text` and solid `accent` fills only.
- **Content** (`panel_flat`): the editor, side bar, bottom panel, tabs, and the hover, suggest, and peek widgets. Tabs and the side bar show colored git and problem labels, and widgets show code, so they stay on the panel where every color passes.
- **Raised** (`raised_flat`): inputs, dropdowns, menus, quick pick, and the command center.
- **Edge** (`edge_flat`): VS Code has no inner top hairline, so the edge is drawn with the borders it does expose along the top of an area: the status bar's top border, the side bar and panel section headers, and the top of the active tab in an unfocused group. The active tab in the focused group keeps its `accent` top border, since that marks state. See [the edge as borders](#the-edge-as-borders).
- **Washes**: selections, find matches, word highlights, and diff and merge lines use a color role at the variant's wash alpha, so the code under them keeps its colors.

## Role mapping

Every color the theme sets.

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
| `window.activeBorder`, `window.inactiveBorder` | `line` |
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
| `statusBar.border` | `edge_flat` |
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
| `sideBar.border` | `line` |
| `sideBarSectionHeader.border` | `edge_flat` |
| `sideBar.dropBackground` | `accent` wash |
| `editorGroupHeader.tabsBackground` | `chrome_flat` |
| `editorGroupHeader.noTabsBackground` | `panel_flat` |
| `editorGroupHeader.tabsBorder`, `editorGroup.border` | `line` |
| `editorGroup.dropBackground` | `accent` wash |
| `tab.activeBackground`, `tab.unfocusedActiveBackground`, `tab.inactiveBackground`, `tab.unfocusedInactiveBackground` | `panel_flat` |
| `tab.activeForeground`, `tab.unfocusedActiveForeground` | `text` |
| `tab.inactiveForeground`, `tab.unfocusedInactiveForeground` | `text_dim` |
| `tab.activeBorderTop` | `accent` |
| `tab.unfocusedActiveBorderTop` | `edge_flat` |
| `tab.border` | `line` |
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
| `panelSectionHeader.border` | `edge_flat` |

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

**Terminal ANSI slots**

| Slot | Dark | Light |
|---|---|---|
| black | `raised_flat` | `text` |
| red, green, yellow, blue, cyan (and bright) | their namesake role | their namesake role |
| magenta, bright magenta | `magenta` | `magenta` |
| bright black | `text_muted` | `text_muted` |
| white | `text_dim` | `line` |
| bright white | `text` | `raised_flat` |

Semantic tokens follow the same table: types, classes, and namespaces are `cyan`, functions, methods, and properties `blue`, enum members, keywords, and macros `magenta`, decorators and events `yellow`, parameters and variables `text`.

## The edge as borders

Each key below was looked up in the [Theme Color reference](https://code.visualstudio.com/api/references/theme-color).

| Key | What the reference says it draws | Role |
|---|---|---|
| [`statusBar.border`](https://code.visualstudio.com/api/references/theme-color#status-bar-colors) | the border separating the status bar and editor, so the top of the status bar | `edge_flat` |
| [`sideBarSectionHeader.border`](https://code.visualstudio.com/api/references/theme-color#side-bar) | the side bar section header border | `edge_flat` |
| [`panelSectionHeader.border`](https://code.visualstudio.com/api/references/theme-color#panel-colors) | the panel section header border, when views are stacked | `edge_flat` |
| [`tab.unfocusedActiveBorderTop`](https://code.visualstudio.com/api/references/theme-color) | the top border of the active tab in an inactive group | `edge_flat` |
| [`window.activeBorder`, `window.inactiveBorder`](https://code.visualstudio.com/api/references/theme-color#window-border) | the border around the window, with the custom title bar | `line` |
| [`input.border`](https://code.visualstudio.com/api/references/theme-color#input-control), [`dropdown.border`](https://code.visualstudio.com/api/references/theme-color#dropdown-control), `checkbox.border`, [`menu.border`](https://code.visualstudio.com/api/references/theme-color#menu-bar-colors), [`commandCenter.border`](https://code.visualstudio.com/api/references/theme-color#command-center-colors), `commandCenter.inactiveBorder` | the whole outline of a raised surface | `line` |

- **One role per key.** A template sets one role for both variants. The window outline and the raised outlines use `line`, which Light calls for (ADR 0009: Light's window outline is `line`, and on white raised surfaces `line` carries the lift). In Dark, `edge_flat` and `line` are one step apart, so Dark looks the same as with the edge.
- **No top-only key for raised surfaces or the title bar.** Inputs, dropdowns, menus, quick pick, and the command center only take a full outline, and quick pick has no border key of its own. `titleBar.border` sits under the title bar, so it stays `line`. A white full outline in Light would erase the white raised surfaces against the panel.
- **Light's edge is white.** On the near-white panel, the section header and tab top edges are barely there, by design: the edge is light catching the glass, not a divider.

## Gaps and trade-offs

- **No glass.** VS Code cannot make its window translucent, so the port is Tier 2 and uses flat values throughout.
- **Selected text keeps its syntax colors.** VS Code only allows a selected text color in high contrast themes, so the selection is an `accent` wash instead of a solid fill.
- **Changed characters inside a diff line** get a thin `green` or `red` border instead of a stronger tint. Two washes on top of each other would drop text below the contrast floor.
- **Rainbow brackets are off.** All bracket pair colors are `text_dim`, since brackets are punctuation.
- **Button hover** does not change color. The palette has one accent, with no hover shade.
- **Line and range highlights** (`editor.lineHighlightBackground`, `editor.lineHighlightBorder`, `editor.rangeHighlightBackground`, `editor.findRangeHighlightBackground`, `editor.hoverHighlightBackground`, `editorInlayHint.background`) stay `raised` with its alpha. The reference asks for three of them not to be opaque, so decorations show through, and they always sit on the solid editor (`panel_flat`), never over the wallpaper. Laid over `panel_flat`, Dark's `raised` comes out exactly `raised_flat`, and Light's is near white, so they meet the raised floor: role colors 3.71 and up in Dark, 4.95 and up in Light. Code on the current line is short of the panel's 4.5 for role colors in Dark, the same as code under a wash.
- **Shadows** under widgets and menus use VS Code's default shadow. The palette has no shadow color.
- **Settings not listed above** keep VS Code's default for the base theme (Dark Modern or Light Modern). That covers newer or rarely seen parts, such as the notebook editor, chat, and the welcome page.
- **Publisher.** `template/package.json` uses `hyaline` as a placeholder publisher ID. Replace it with the real Marketplace publisher ID once one exists, then rebuild.
- **Still to do.** Testing both install paths, filling in "Tested with", screenshots, the publisher ID, and Marketplace publishing are tracked in [issue #14](https://github.com/mookeyj79/Hyaline/issues/14).

## Research

- [Diff editor color defaults](https://github.com/microsoft/vscode/blob/main/src/vs/platform/theme/common/colors/editorColors.ts): diff line and text colors default to VS Code tints, so both are set.
- Every workbench color key used here was checked against the [Theme Color reference](https://code.visualstudio.com/api/references/theme-color).
- Ports studied: [Catppuccin for VS Code](https://github.com/catppuccin/vscode) and [Nord for VS Code](https://github.com/nordtheme/visual-studio-code), both MIT. Method only: which workbench keys to cover, `semanticHighlighting`, and the recommended `terminal.integrated.minimumContrastRatio` and `window.titleBarStyle` settings. No files or colors reused.
