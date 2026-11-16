# Chrome carries what passes everywhere

Supersedes ADR 0004.

ADR 0004 split the window into clear chrome and dense content because one alpha over one wallpaper could not be both. With the glass now clamped (ADR 0008) and the flat values chosen (ADR 0009), the split is kept, on measured grounds. A role may sit on chrome only if it passes the contrast floor there in every case: flat, clamped glass, and opacity only. The worst case is Light with opacity only over pure black, where only primary text passes (4.79). So chrome carries primary `text` and solid fills (accent or a color role, with `on_accent`) and nothing else, in both variants.

Chrome or content is decided by what an area shows, not by its name. An area that frames content and shows only primary text and solid fills is chrome. An area that shows dim, muted or colored text is content and goes on the panel, wherever it sits. VS Code's tabs and side bar show git colors and dim inactive tabs, so they stay on the panel; Typora's file sidebar is chrome.

## Considered options

- **More on Dark chrome than Light.** Dark's chrome passes every role in flat and on clamped glass. Turned down: it breaks "two variants, one theme" and buys little.

## Consequences

- No washes on chrome. A selected or active item on chrome is a solid fill; a hover is `raised`. Cinnamon's panel bar drag highlights change from washes to solid fills.
- The check script measures primary text on chrome, on `raised` over chrome, and on solid fills, for flat values and for translucent surfaces over black and white.
- Light's pinned `panel_flat` from ADR 0004 is gone: every flat value is chosen (ADR 0009).
