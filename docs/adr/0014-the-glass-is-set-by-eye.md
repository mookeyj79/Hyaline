# The glass is set by eye

Amends [ADR 0008](0008-the-glass-clamps-the-backdrop.md) and [ADR 0011](0011-the-contrast-floor-holds-over-any-backdrop.md).

The clamp made the glass pass the contrast floor over pure black and pure white, and that made it look flat: the panels hid the wallpaper. Plain glass, a tint and a blur, cannot pass over both extremes at any opacity that still shows the wallpaper. Over the wallpapers Hyaline ships it reads well. So the glass is set by eye, per variant, and the contrast floor holds on solid surfaces only.

| Variant | With blur | Without blur | Raised |
|---|---|---|---|
| Dark | 35% transparent, 6.5 px blur | 20% transparent | 10% white |
| Light | 40% transparent, 6.5 px blur | 15% transparent | 50% white |

Chrome and panel take the same values. There is no clamp: the palette's `glass` block holds only the blur and the alpha used with it. Raised keeps its alpha with or without blur. The two variants do not share numbers; each is set where it looks right.

## Considered options

- **Keep the clamp.** Passes everywhere, but the glass shows nothing.
- **Measure each variant over its own wallpapers.** Closer, but the numbers still failed where the glass read fine by eye.

## Consequences

- `glass_floor` is false for both variants in `palette/palette.json`. The checks still measure the glass over black and white and list it as "by eye", but only solid surfaces fail: the flat values, fills, and washes over `panel_flat`.
- The flat values keep their own floor, so every port that cannot do glass stays readable.
- Tier 1 (Full glass) no longer promises that glass passes over any backdrop.
