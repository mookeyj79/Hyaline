# Wallpapers are found images, chosen by taste

Supersedes ADR 0003.

Hyaline ships wallpapers as the backdrop behind its glass. They are found photos or art, not images generated from the palette, and they stay the one exception to "no color values outside the palette": image assets in their own folder, skipped by the raw-color check. Every wallpaper needs a license that allows redistribution (CC0, public domain, CC BY, CC BY-SA) and a recorded credit.

What changes is why a wallpaper fits. ADR 0003 required light, low-detail, low-saturation images shared by both variants, because the glass relied on them. The glass now keeps text readable over any backdrop (ADR 0008, ADR 0011), so the backdrop can be anything, and choosing a wallpaper is a matter of taste.

## Consequences

- The `backdrop` fill differs per variant: slate `#2c323b` in Dark, mist `#dfe6ee` in Light.
- Each wallpaper is marked with the variant it suits: `dark`, `light` or `both`. The finder suggests a mark from lightness, and a person decides.
- Wallpapers come in pairs where possible: two images of the same kind of subject in a matching style, one for each variant. A pair is judged by eye, not measured. Pairs are shown before single images.
- Lightness, saturation and detail are grades that rank search results, not gates. License and format (a landscape JPEG at least 1920 px wide) stay gates.
- Wallpapers are no longer checked for contrast behind the glass.
