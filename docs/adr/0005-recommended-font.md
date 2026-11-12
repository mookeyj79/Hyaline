# One recommended font: FiraCode Nerd Font

Sameness across apps is the point of Hyaline, and type is half of how an app looks. So Hyaline recommends one font and every port's install guide sets it where the app allows.

The font is **FiraCode Nerd Font**, and apps should pick its **Mono** version:

- **Monospaced.** That is the one hard requirement. The Mono version also keeps every icon one cell wide, so terminal columns and prompts always line up.
- **Nerd Font icons.** Shell prompts, file trees, and status lines use them (branch, folder, check, cross).
- **Programming ligatures** (`=>`, `!=`, `->`), which can be turned off in apps that allow it.
- **Free and redistributable** under the SIL Open Font License 1.1, so the preview page can bundle it.
- The preview page already used Fira Code, so the look stays the same.

## Consequences

- Every port README has a **Set the font** section linking to the font. Apps that cannot change their font say so.
- The preview page bundles a trimmed copy of the font in `Ports/preview/assets/fonts/` with its license.
- The font is a recommendation, not a requirement: a port still works with any monospaced font.
