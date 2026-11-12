# Port icons are single-color and follow the palette rule

The ports page shows each port as a card. Cards carried only a text monogram, so they gave no quick way to spot an app. Each port can now have an icon. The open question was whether icons are found images that are exempt from the palette rule, like wallpapers (ADR 0003), or whether they must follow it.

They follow it. An icon is a single-color SVG shape with no color of its own. The page tints it with `text` (dimmed on planned cards), so it reads on Hyaline Dark and Hyaline Light cards without extra work, and every card stays in the palette. Full-color app logos are out: they would need the exemption, and they would clash with each other and with the glass.

Icons come from two open sets, in this order:

1. **Brand mark** from [Simple Icons](https://simpleicons.org/) (CC0), when it has the app and the app's own license or brand guidelines allow its mark to be shown. This is the most recognizable option.
2. **Glyph** from [Lucide](https://lucide.dev/) (ISC), a symbol for what the app is (a terminal, a code editor), when there is no usable brand mark. Many apps fall here. Microsoft, for example, had its marks removed from Simple Icons.

The monogram stays as the fallback when a port has no icon, or when the icon fails to load.

## Consequences

- Cards mix two styles: filled brand marks and outlined glyphs. We accept this for recognition. To keep them close, the page draws brand marks slightly smaller, since they fill their whole box and glyphs do not.
- Each icon is `Ports/<app_name>/icon.svg`, and its credit (kind, source set, author, source URL, license, plus where the mark's use is allowed for brand marks) is the `icon` object in `port.json`. `check.ps1` requires both or neither.
- `check.ps1` rejects any icon that has a color value other than `currentColor` or `none`, anything beyond basic shapes, or a viewBox other than `0 0 24 24`.
- `build/icon.ps1` searches both sets and fetches an icon at a pinned version. The `port-icon` skill walks through the choice.
