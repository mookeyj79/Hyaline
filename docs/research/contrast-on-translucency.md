# How others keep text readable on translucent surfaces

Research for [issue #89](https://github.com/mookeyj79/Hyaline/issues/89), part of the map in [issue #86](https://github.com/mookeyj79/Hyaline/issues/86). Read on 2026-11-17. Primary sources only: vendor docs, W3C documents, and the APCA reference code. The numbers come from `docs/research/contrast-on-translucency.py`, which reads `palette/palette.json` (version 1.0.0).

The earlier note [How OS glass stays readable over any wallpaper](https://github.com/mookeyj79/Hyaline/blob/archive/research/os-glass-readability/docs/research/os-glass-readability.md) (tag `archive/research/os-glass-readability`) has the material recipes (blur, clamp, tint numbers). This note covers only the text side: what each source says about contrast, and how it is measured.

## Short answer

- **Nobody measures through translucency.** Apple and Microsoft keep text readable by making the material do the work (a luminosity clamp, thicker material for text) and by restricting what text goes on it. Both state the plain WCAG 2 AA ratios (4.5 and 3) as the bar. Neither publishes a method for measuring contrast through a translucent layer.
- **WCAG 2 measures the background actually behind the letters**, and for a varying background it checks the worst part. The W3C's own test rule says there is "no clear method" when some background pixels pass and some do not. Hyaline's black-and-white bound (ADR 0011) is the strict reading of that: for a tint at a fixed opacity, black and white are the two worst backgrounds.
- **APCA is not ready to adopt.** It was in the WCAG 3 draft in 2021, was removed by July 2023, and the September 2026 draft says the contrast algorithm "is yet to be determined". The reference code has been at 0.1.9 (beta) since July 2022, and its licence limits use to web content and forbids changing the constants.
- **APCA would not let 75 percent through anyway.** At the levels APCA calls minimums (Lc 75 for body text, Lc 60 for other content text), Light at 75 percent fails every row, including primary text. Dark at 75 percent fails dim text and every role color at Lc 75, and six of seven role colors at Lc 60. APCA is also stricter than WCAG 2 for today's palette: no role color in either variant reaches Lc 75 even on the solid `panel_flat`.

## Apple: materials and vibrancy

- **The bar is WCAG 2 AA.** HIG Accessibility names two "popular standards of measure for color contrast", WCAG and "the Accessible Perceptual Contrast Algorithm (APCA)", and says Accessibility Inspector "uses the following values from WCAG Level AA": 4.5:1 up to 17 pt, 3:1 at 18 pt and for bold. Source: [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), section "Color and effects" (page updated June 9, 2025).
- **Text on a material uses vibrant colors.** "Help ensure legibility by using vibrant colors on top of materials. When you use system-defined vibrant colors, you don't need to worry about colors seeming too dark, bright, saturated, or low contrast in different contexts." Source: [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials).
- **Thickness is the contrast lever.** "Thicker materials, which are more opaque, can provide better contrast for text and other elements with fine features." Vibrancy levels are named by contrast (default highest, quaternary lowest), and "avoid using quaternary on top of the thin and ultraThin materials, because the contrast is too low". Same page.
- **Glass for text clamps luminosity.** The regular Liquid Glass variant "blurs and adjusts the luminosity of background content to maintain legibility of text"; use it "when components have a significant amount of text". The clear variant gets an optional dark dimming layer "of 35% opacity" over bright content. Same page.
- **Colors near translucency shift.** "Colors can also appear different when placed behind or applied to a translucent element like a toolbar." Source: [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color).
- **No measuring method.** Apple publishes no way to measure contrast through a material. The guidance is: pick the material and vibrancy level by purpose, then test, and supply an Increase Contrast variant if the default misses the minimum (HIG Accessibility).

## Microsoft: Acrylic and Mica

- **The bar is WCAG 2 AA via G18.** "visible text must have a minimum luminance contrast ratio of 4.5:1 against its background", aligned with WCAG technique G18. For apps the tools cannot inspect, "make screen captures of app UI and then run the contrast ratio tool over the screen capture image." Source: [Accessible text requirements](https://learn.microsoft.com/en-us/windows/apps/design/accessibility/accessible-text-requirements) (ms.date 2026-08-21).
- **Acrylic: the resources are tuned, the text is restricted.** "We've optimized the acrylic resources such that text meets contrast ratios on top of acrylic. We don't recommend placing accent-colored text on your acrylic surfaces because these combinations are likely to not pass minimum contrast ratio requirements at the default 14px font size. Try to avoid placing hyperlinks over acrylic elements. Also, if you choose to customize the acrylic tint color or opacity level, keep the impact on legibility in mind." Source: [Acrylic material](https://learn.microsoft.com/en-us/windows/apps/design/style/acrylic), "Legibility considerations" (ms.date 2026-10-02). The tuning is the luminosity layer: 85 percent (Light) and 96 percent (Dark) of the lightness comes from the tint, not the backdrop (see the earlier note).
- **Mica: opaque, and content sits on a layer.** Mica is "an opaque, dynamic material"; content goes on a content layer filled with `LayerFillColorDefaultBrush`, "a low-opacity solid color". Source: [Mica material](https://learn.microsoft.com/en-us/windows/apps/design/style/mica) (ms.date 2026-07-22). Mica samples the wallpaper once and is opaque, so text contrast is measured against a solid color.
- **No measuring method.** Microsoft does not say how "text meets contrast ratios on top of acrylic" was verified, or against which backdrops.

## WCAG 2: text over images and varying backgrounds

- **Measure what is behind the text in normal use.** "contrast is measured with respect to the specified background over which the text is rendered in normal usage." Source: [Understanding SC 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html). The thresholds are not rounded: "4.499:1 would not meet the 4.5:1 threshold". The Understanding page does not address transparency or alpha.
- **G18 measures per letter.** Measure each letter's luminance and "the background pixels immediately next to the letter". If the background varies, the letters must "maintain a 4.5:1 contrast ratio with the background behind them even if they do not have that contrast ratio with the entire background". Fixes it names: shade the background behind the text, outline the letters, or a halo. Its photo example fogs the image white so "the maximum darkness is still light enough to maintain a 4.5:1 contrast ratio". Source: [G18](https://www.w3.org/WAI/WCAG22/Techniques/general/G18).
- **F83 checks the worst area first.** Failure F83 (background images without enough contrast) has a quick check: contrast between the text and "the area of the image that is darkest (for dark text) or lightest (for light text)". If that passes, there is no failure; if not, check behind each letter. Source: [F83](https://www.w3.org/WAI/WCAG22/Techniques/failures/F83).
- **The test rule admits the gap.** ACT rule afw4f7 (Text has minimum contrast, 30 August 2023) passes text if the highest possible contrast between its colors and the background's colors meets the ratio, then warns: "There is no clear method for determining legibility when some but not all pixels have sufficient contrast, which is why passing this rule does not necessarily mean the corresponding success criterion is met." Its failed examples include semi-transparent text measured over each part of a black-and-white background ("between 2.3:1 and 4.2:1"). Source: [afw4f7](https://www.w3.org/WAI/standards-guidelines/act/rules/afw4f7/).
- **Tools composite alpha in sRGB.** axe-core walks the stack of elements behind text, blends semi-transparent layers bottom-up into one color, and gives up (no result) when a layer has a background image. Source: [get-background-color.js](https://github.com/dequelabs/axe-core/blob/develop/lib/commons/color/get-background-color.js). This is the same model as Hyaline's `Get-Blend`, but it only works when every layer is a known color.

**What this means for Hyaline.** WCAG 2 has no rule for a translucent surface over an unknown backdrop. The closest is F83's quick check: measure against the worst background that can appear. ADR 0011's pure black and pure white is that check taken to its limit. Option 2 in #85 (a dark-ish limit for Light) is also F83-shaped, but only holds if the wallpaper can never be darker than the limit, which Hyaline cannot promise.

## A published method for measuring through translucency

None found from a standards body or platform vendor. What exists:

- WCAG 2's method: composite to the actual pixels, then measure (G18, F83, afw4f7). Each assumes the backdrop is known.
- APCA's reference code has an `alphaBlend` helper for semi-transparent text: "Only the foreground has an alpha" and "There is no conversion to linear space, so blending takes place is the working colorspace". Source: [apca-w3 README](https://github.com/Myndex/apca-w3). Again, it assumes a known background.

The bounding argument in ADR 0011 (a fixed tint over any backdrop lies between its results over black and over white) is Hyaline's own. It follows from the compositing above: with gamma-space blending, each channel of the composite is linear in the backdrop channel, so the composite's luminance is lowest over black and highest over white.

## APCA: is it stable and specified enough?

| Question | Finding | Source |
|---|---|---|
| In WCAG 3? | No. The 2021 draft scored "Visual contrast of text" against "the APCA lookup table". The July 2023 draft dropped it. The 10 September 2026 draft has "Text contrast sufficient (minimum)" at Developing status with the text "meets @@[contrast measure to be determined]" and the note "The contrast algorithm used in WCAG 3 is yet to be determined." | [WD 2021-12-07](https://www.w3.org/TR/2021/WD-wcag-3.0-20211207/), [WD 2023-07-24](https://www.w3.org/TR/2023/WD-wcag-3.0-20230724/), [current WD](https://www.w3.org/TR/wcag-3.0/), [informative page, updated 31 July 2026](https://www.w3.org/WAI/WCAG3/informative/text-and-wording/text-appearance/text-contrast-sufficient-minimum/) |
| Versions | Algorithm 0.0.98G-4g (15 February 2021). Library apca-w3 0.1.9 "beta", published to npm on 4 July 2022, still the latest. | [apca-w3 README](https://github.com/Myndex/apca-w3), [npm registry](https://registry.npmjs.org/apca-w3) |
| Licence | "Limited W3 License". Licensed to the W3C "for use with WCAG accessibility guidelines for web-delivered and web-based content only, and not for any other use". Use must be "without modification to the essential elements of the code or specific approved constants". Implementations that are wrong or out of date "shall be deemed in breech of license". Other uses fall under AGPL v3. Patent pending. | [LICENSE.md](https://github.com/Myndex/apca-w3/blob/master/LICENSE.md) |
| Its own guidelines | The APCA Readability Criterion (ARC) is a "Public Beta Draft" (12 March 2023), "not presently an official recommendation". | [ARC](https://readtech.org/ARC/) |
| Platform use | Apple names it as a popular standard but its own tool uses WCAG 2 AA values. Microsoft does not mention it. | [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) |

Read plainly: the math is fixed and has not changed since 2021, so numbers are reproducible. But no standard adopts it, its thresholds live in a beta draft by its own authors, and the licence names web content only. Hyaline's ports are mostly desktop apps (terminals, editors). Using the reference constants in a check script for a desktop theme is outside the licence's stated scope; that is a question for the licence holder, not something this note can settle.

### APCA thresholds

From [APCA in a Nutshell](https://git.apcacontrast.com/documentation/APCA_in_a_Nutshell) and the [ARC Bronze Simple Mode](https://readtech.org/ARC/tests/bronze-simple-mode/) (Draft). Lc is reported as an absolute value here; APCA gives light text on dark a negative sign.

| Level | Use (Nutshell) | Bronze Simple Mode |
|---|---|---|
| Lc 90 | Preferred for body text, fonts no smaller than 14px/400 | Body text, preferred |
| Lc 75 | Minimum for body text, fonts no smaller than 18px/400, 16px/500 or 14px/700 | Body text, minimum ("more than two continuous lines") |
| Lc 60 | Minimum for "content text that is not body, column, or block text", from 24px/400 or 16px/700 down; add 15 to use those sizes as body text | Other content text, minimum ("up to two and a half lines") |
| Lc 45 | Larger, heavier text: 36px/400 or 24px/700, headlines | Large text over 36px |
| Lc 30 | "The absolute minimum for any text not listed above", spot-readable text, placeholder and disabled text | Not covered ("Spot text ... is not covered") |
| Lc 15 | Minimum for non-text that must be discernible | Not covered |

For the ticket's three cases:

- **Body text** (`text`, and running code in role colors): Lc 75 minimum, Lc 90 preferred. At a typical terminal size (13 to 14px, weight 400), the Nutshell size table puts body text at the Lc 90 row; Lc 75 assumes 18px/400.
- **Dim or secondary text** (`text_dim`, `text_muted`): APCA has no "dim" class. Short non-body content is Lc 60; spot text is Lc 30. Comments in code are read, so Lc 60 is the honest fit.
- **Short labels** (badges, inline code, a tag in a tab): Lc 60 as short content text at 16px/700 or larger; Lc 30 only if treated as spot text.

## APCA values for the panel rows

Method: the panel tint (`#1c2028` Dark, `#ffffff` Light) composited over pure black and pure white at the given alpha, per channel in gamma-encoded sRGB and rounded to whole values, as `Get-Blend` in `build/lib/Palette.psm1` does. Then each text color is measured against both composites, and the lower |Lc| counts, as ADR 0011 does for WCAG 2. APCA uses the apca-w3 0.1.9 constants (0.0.98G-4g); the script reproduces the eight expected values in that package's `test/index.js` exactly.

**Sanity check against #85.** The script's WCAG 2 numbers match #85's table to the hundredth when the composite is not rounded. `Get-Blend` (and so `check.ps1`) rounds each channel, which lowers some ratios by up to 0.03 at 75 percent (Dark `text` 6.52 rounded against 6.55 in #85). No pass or fail changes. APCA moves by 0.2 at most. The script prints both.

Over black and over white, |Lc|, with the WCAG 2 result (worse of the two, rounded composite) beside it. **Bold** is below Lc 60.

### Dark

Composites: 75 percent `#15181e` over black, `#55585e` over white. 82 percent `#171a21` and `#45484f`.

| Row | WCAG 75% | Lc 75% (black / white / worse) | WCAG 82% | Lc 82% (black / white / worse) |
|---|---|---|---|---|
| text | 6.52 | 100.0 / 82.9 / 82.9 | 8.38 | 99.7 / 88.7 / 88.7 |
| text_dim | 4.88 | 80.3 / 63.2 / 63.2 | 6.27 | 80.1 / 69.0 / 69.0 |
| text_muted | 3.73 | 64.8 / 47.7 / **47.7** | 4.79 | 64.6 / 53.5 / **53.5** |
| red | 3.87 | 66.9 / 49.9 / **49.9** | 4.97 | 66.7 / 55.6 / **55.6** |
| green | 4.59 | 76.7 / 59.6 / **59.6** | 5.90 | 76.5 / 65.4 / 65.4 |
| yellow | 4.93 | 80.9 / 63.8 / 63.8 | 6.32 | 80.7 / 69.6 / 69.6 |
| blue | 3.95 | 68.0 / 51.0 / **51.0** | 5.07 | 67.8 / 56.7 / **56.7** |
| magenta | 3.82 | 66.3 / 49.2 / **49.2** | 4.91 | 66.1 / 55.0 / **55.0** |
| cyan | 4.44 | 74.7 / 57.7 / **57.7** | 5.71 | 74.5 / 63.4 / 63.4 |
| orange | 4.21 | 71.6 / 54.5 / **54.5** | 5.41 | 71.4 / 60.3 / 60.3 |

### Light

Composites: 75 percent `#bfbfbf` over black, `#ffffff` over white. 96 percent `#f5f5f5` and `#ffffff`.

| Row | WCAG 75% | Lc 75% (black / white / worse) | WCAG 96% | Lc 96% (black / white / worse) |
|---|---|---|---|---|
| text | 8.74 | 66.3 / 103.0 / 66.3 | 14.74 | 97.0 / 103.0 / 97.0 |
| text_dim | 4.39 | 51.3 / 88.0 / **51.3** | 7.41 | 82.0 / 88.0 / 82.0 |
| text_muted | 2.71 | 37.7 / 74.4 / **37.7** | 4.56 | 68.5 / 74.4 / 68.5 |
| red | 2.75 | 37.3 / 74.0 / **37.3** | 4.64 | 68.0 / 74.0 / 68.0 |
| green | 2.75 | 37.9 / 74.6 / **37.9** | 4.64 | 68.7 / 74.6 / 68.7 |
| yellow | 2.75 | 38.1 / 74.8 / **38.1** | 4.63 | 68.8 / 74.8 / 68.8 |
| blue | 2.74 | 37.7 / 74.4 / **37.7** | 4.62 | 68.4 / 74.4 / 68.4 |
| magenta | 2.71 | 37.2 / 73.9 / **37.2** | 4.58 | 67.9 / 73.9 / 67.9 |
| cyan | 2.80 | 38.5 / 75.2 / **38.5** | 4.72 | 69.2 / 75.2 / 69.2 |
| orange | 2.71 | 37.6 / 74.3 / **37.6** | 4.58 | 68.3 / 74.3 / 68.3 |

### On the solid panel, for reference

On `panel_flat` (Dark `#434850`, Light `#fafbfc`), |Lc|: Dark text 88.8, text_dim 69.1, text_muted 53.6, roles 55.1 (magenta) to 69.7 (yellow). Light text 100.5, text_dim 85.5, text_muted 72.0, roles 71.4 (magenta) to 72.7 (cyan).

### What the tables say

- **At Lc 75 (body text minimum)**, only primary text passes in Dark at either alpha, and primary and `text_dim` in Light at 96 percent. Light primary text at 75 percent (66.3) fails. No role color passes in either variant at any alpha, nor on the solid panel. Light's roles top out at about Lc 75 over pure white itself. APCA at body-text level would reject today's palette everywhere, not just on thin glass.
- **At Lc 60 (other content text):**
  - Dark 75 percent fails `text_muted` and six of seven roles (all but yellow; green is 59.6). Dark 82 percent still fails `text_muted`, red, blue and magenta.
  - Light 75 percent fails everything but primary text, and primary text (66.3) fails Lc 75. Light 96 percent passes every row.
- **At Lc 45 (large text)**, Dark 75 percent passes every row and Light 75 percent still fails every row except `text` and `text_dim`.
- **APCA ranks the two variants the other way round from WCAG 2.** WCAG 2 says Dark at 75 percent is close (roles 3.82 to 4.93 against 4.5) and Light is far off (2.71 to 2.80). APCA agrees Light is far off, but also puts Dark's roles at Lc 49 to 64, in the same band as Light at 96 percent (Lc 68 to 69). This is APCA's stated view that WCAG 2 "far overstates contrast for dark colors" ([APCA in a Nutshell](https://git.apcacontrast.com/documentation/APCA_in_a_Nutshell)).

So option 4 in #85 (a perceptual measure for opacity-only glass) does not buy 75 percent. Under APCA's own minimums, 75 percent fails in both variants, and by more than WCAG 2 says for Dark. Any APCA bar low enough to pass 75 percent Light (about Lc 37) is below its Lc 45 large-text level and only meets the Lc 30 spot-text level.

## Not verified

- **Why APCA left the WCAG 3 draft.** The 2023 draft says only "We removed old material that was not consistent with the new approach." No AGWG decision record was read.
- **Whether a desktop theme's check script may use the APCA constants.** The licence text says web content only. Not asked of the licence holder.
- **Microsoft's Fluent 2 site** ([fluent2.microsoft.design](https://fluent2.microsoft.design/material)) was not read; the Windows Learn pages were.
- **Apple's vibrancy math.** Apple does not publish how vibrant label colors are blended, so their contrast over a material cannot be computed.
- **The APCA Nutshell page** on `git.apcacontrast.com` was read through a summary tool. Its threshold wording was checked against the copy shipped in the apca-w3 0.1.9 package (`docs/APCA_in_a_Nutshell.md`).
- **The APCA numbers were not cross-checked by running apca-w3 itself.** The script copies its constants and formula and matches its eight test values exactly.
