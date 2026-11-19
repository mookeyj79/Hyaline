# The contrast floor holds over any backdrop

Amends ADR 0006. Amended by [ADR 0013](0013-opacity-only-glass-has-its-own-floor-rows.md): opacity-only glass has its own rows of the floor. Amended by [ADR 0014](0014-the-glass-is-set-by-eye.md): the floor holds on solid surfaces; the glass is set by eye.

The contrast floor was measured against the flat fallback, "since that is the worst case". With a backdrop that can be anything and glass that must pass with or without blur (ADR 0008), it no longer is. The floor now names the surface under the text, not the app setting or the tier: a solid surface is measured as drawn, and a translucent surface over pure black and pure white, after whatever the port applies (a clamp counts, blur does not). The lower result counts. For a tint at a fixed opacity, black and white bound every possible backdrop, so no other test image is needed.

| On | Primary text | Dim text | Muted text | Role colors |
|---|---|---|---|---|
| Panel | 4.5 | 4.5 | 3 | 4.5 |
| Raised | 4.5 | 4.5 | 3 | 3, short labels only |
| Chrome | 4.5 | n/a | n/a | n/a |
| A wash | 4.5 | 3 | 3 | 3 |

Two cases fell below the old floor once the flat values became the glass as it looks (ADR 0009), and they are settled by where roles sit, not by new values:

- **Role colors on raised** (Dark 3.71 to 4.78) are short labels: inline code, badges, a tag in a tab. Running colored text goes on the panel.
- **Dim text on a wash** (Dark 4.23 to 4.49) needs 3. A wash marks a line, the line is read through its primary text, and dim text there is punctuation and supporting detail.

## Considered options

- **Keep 4.5 and exempt Dark's dim text on a wash.** An exemption that sits in the checks forever.
- **Keep dim text off washes.** Most apps cannot, and in code dim text is punctuation.

## Consequences

- ADR 0006's wash rule changes: dim text on a wash needs 3, not 4.5. Its wash alphas become 0.18 (Dark) and 0.24 (Light).
- `on_accent` on an accent fill needs 4.5. Borders that mark state (focus, an active tab, an error) are role colors and need 3 against their surface. `line` and `edge` carry no meaning and have no floor.
- The check script measures translucent surfaces over black and white as well as the flat values, and role colors on raised become a failure under 3, not a warning.
- No wallpaper can make the glass fail, so wallpapers are no longer checked for contrast (ADR 0012).
