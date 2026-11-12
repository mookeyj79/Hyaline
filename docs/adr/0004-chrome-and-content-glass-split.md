# Chrome is clear glass, content is dense glass

One panel alpha cannot be both see-through and readable. Measured over the first wallpaper (White Sands) with an 18 px blur, Hyaline Light's panel at alpha 0.62 dropped `text_muted` and every color role to about 3:1, and only passed from 0.93. Hyaline Dark passed at 0.8, but only just.

So the window is split in two. **Chrome** (title bars, tabs, sidebars, toolbars) is clear glass and carries only primary `text` and solid accent fills. **Content** stays on `panel`, which is dense enough that every role passes over a wallpaper. This follows how desktop glass usually works: the frame shows the backdrop, the page you read does not.

New roles in palette 0.2.0:

| Role | Dark | Light |
|---|---|---|
| `chrome` | smoke at 0.70 | frost at 0.30 |
| `chrome_flat` | tint over `backdrop` at that alpha | same |
| `panel` | 0.80 (unchanged) | 0.93 (was 0.62) |

Dark chrome stops at 0.70 because tab labels sit on `raised`, which lightens dark glass. Light chrome reaches 0.30.

## Consequences

- Ports that can tell chrome from content use `chrome` for the frame. Ports that cannot use `panel` everywhere.
- Hyaline Light's `panel_flat` stays at the frost tint (`#f3f6f9`) instead of following the new alpha, which would make it near-white. Flat Light ports keep their look. This is the one flat value that is not derived.
- The check script requires primary `text` to pass on `chrome_flat`.
- Every new wallpaper is checked against both surfaces, and the result is recorded in `wallpapers/README.md`.
