# The glass clamps the backdrop

Amended by [ADR 0013](0013-opacity-only-glass-has-its-own-floor-rows.md): opacity-only glass passes its own rows of the contrast floor, and Light's panel alpha is 0.82.

Hyaline's glass used to rely on the wallpaper: a thin tint, a blur, and a rule that wallpapers be light and calm. No OS glass works that way. Each one blurs hard, then pulls the backdrop's lightness toward a chosen near-white or near-black and lets only its hue through, so text stays readable over anything. So the glass is now responsible for readability, not the wallpaper.

Where the app allows backdrop filters (CSS), the glass blurs 30 px, squeezes the backdrop into a light band (Light) or a dark band (Dark), boosts its saturation, and lays a thin tint on top. The panel is clamped harder than the chrome.

| Surface | Blur | Contrast | Brightness | Saturate | Tint |
|---|---|---|---|---|---|
| Dark chrome | 30 px | 0.35 | 0.5 | 1.8 | smoke `#1c2028` at 0.45 |
| Dark panel | 30 px | 0.15 | 0.45 | 2.5 | smoke at 0.60 |
| Light chrome | 30 px | 0.35 | 1.55 | 1.8 | frost `#ffffff` at 0.30 |
| Light panel | 30 px | 0.10 | 2.1 | 3 | frost at 0.55 |

Most translucent apps offer only a tint color and one opacity, and blur, where there is any, is an on/off request. Those apps use a tint dense enough to pass over pure black and pure white: Dark chrome 0.74 and panel 0.82, Light chrome 0.55 and panel 0.96. Blur is welcome but never counted on.

## Considered options

- **Tint only, at every app's density.** Works everywhere, but throws away the glass where CSS can do better.
- **Solid content, glass only on chrome.** Readable, but the page stops being glass.

## Consequences

- Tier 1 (Full glass) promises a result, not a method: translucent surfaces that pass the contrast floor over any backdrop, with or without blur. The clamp and the dense tint both qualify. Windows Terminal and GNOME Terminal stay Tier 1.
- One translucent surface is enough for Tier 1. It shows colored text, so it is content and takes the panel values.
- Tier 1 ports also ship flat, since the user or the OS can turn glass off.
- A port's tier is the best it delivers using settings the app or OS supports. Glass that needs a patch to the app's own files does not count, so VS Code stays Flat.
- With opacity only, raised surfaces are solid (`raised_flat`). Any lightening of Dark's raised over a white wallpaper fails colored text.
- Opacity-only apps set a limit on Dark's role colors: a white wallpaper lightens Dark's panel under its tint, so Dark's colors cannot go much darker than they are.
