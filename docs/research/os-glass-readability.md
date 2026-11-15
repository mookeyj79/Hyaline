# How OS glass stays readable over any wallpaper

Research for [issue #29](https://github.com/mookeyj79/Hyaline/issues/29), part of the map in [issue #28](https://github.com/mookeyj79/Hyaline/issues/28). Read on 2026-11-15. Primary sources only: vendor docs and vendor source code. Each claim links to the page or file that owns it.

Two labels are used throughout:

- **Documented**: the number is in the linked doc or source file.
- **Not published**: the vendor describes the behavior but gives no number. Nothing here is guessed.

## Short answer

No system relies on the wallpaper. Each one does the same three things:

1. **Blur hard**, so detail is gone before text sits on it.
2. **Clamp lightness**, not only tint. A layer forces the result to be nearly as light (or dark) as a chosen color and lets only hue and saturation through. This is the step Hyaline lacks.
3. **Limit what goes on the glass.** Thin glass carries little text, in system colors only. Dense reading surfaces are opaque or nearly so. A solid fallback color is authored per mode for when transparency is off.

Windows is the only system that publishes a full recipe with numbers. KDE publishes its numbers in source. Apple publishes rules and no numbers. GNOME does not blur app windows at all.

## Numbers at a glance

| | Blur | Tint and lightness clamp | Saturation | Noise | Dark mode | Fallback |
|---|---|---|---|---|---|---|
| **Windows Acrylic** | Gaussian, standard deviation 30 | Light: lightness held 85% to `#FCFCFC`, tint 0%. Dark: lightness held 96% to `#2C2C2C`, tint 15% | none in the current recipe (1.25 in the old one) | 2% opacity | own recipe, denser | Light `#F9F9F9`, Dark `#2C2C2C` |
| **Windows Mica** | not published | not published; opaque | not published | not published | own recipe | Light `#F3F3F3`, Dark `#202020` |
| **macOS materials** | not published | not published; five named thicknesses | not published | not published | "varies with light and dark appearance" | opaque when Reduce Transparency is on |
| **KDE KWin blur** | strength 15 of 15 (dual Kawase, no pixel radius) | set by the Plasma theme SVG, not by KWin | 150% | strength 5 of 14 | theme decides | theme's opaque SVG set |
| **GNOME Shell** | radius 90 (lock screen only) | brightness times 0.65 | none | none | same recipe | apps are opaque already |

## Windows: Acrylic

Acrylic is the frosted glass used for menus and flyouts.

**The layers.** Microsoft Learn names them: "background, blur, exclusion blend, color/tint overlay, noise". It says the exclusion layer was added "to ensure contrast and legibility of UI placed on an acrylic background". Source: [Acrylic material](https://learn.microsoft.com/en-us/windows/apps/design/style/acrylic), section "How we designed acrylic". The doc gives no numbers.

**The numbers** are in the WinUI source, [AcrylicBrush.h](https://github.com/microsoft/microsoft-ui-xaml/blob/main/controls/dev/Materials/Acrylic/AcrylicBrush.h) and [AcrylicBrush.cpp](https://github.com/microsoft/microsoft-ui-xaml/blob/main/controls/dev/Materials/Acrylic/AcrylicBrush.cpp). All documented:

| Constant | Value |
|---|---|
| `sc_blurRadius` | 30.0, passed to a Gaussian blur as `BlurAmount` |
| `sc_noiseOpacity` | 0.02 |
| `sc_exclusionColor` | white at alpha 26 of 255 (about 10%) |
| `sc_saturation` | 1.25 |

The blur amount is a standard deviation in device-independent pixels, and the kernel radius is three times that. Source: [Direct2D Gaussian blur effect](https://learn.microsoft.com/en-us/windows/win32/direct2d/gaussian-blur).

**The recipe changed.** The current code no longer uses the exclusion color or the saturation constant. They are still declared in the header, but the effect graph in `AcrylicBrush.cpp` is the "Shadow-friendly Luminosity-based Recipe", introduced in Windows 10 19H1. Back to front:

1. The backdrop, composited over the opaque fallback color so the blur has no transparent edges.
2. Gaussian blur, 30.
3. **Luminosity blend.** The source comment explains it: the blend "takes the color (Hue and Saturation) values from our blurred backdrop, but gets the lightness (Luminosity) value from a solid color layer". The color is the tint color at an alpha called luminosity opacity. "The purpose is to reduce contrast - allowing colors to come through, but blocking sharp differences in brightness".
4. **Color blend** with the tint color at the tint opacity.
5. Noise texture at 2% opacity, tiled.

So the Learn page still describes the older exclusion recipe, and the shipped code uses a luminosity layer for the same job.

**Default brushes** for Windows 11, from [AcrylicBrush_themeresources.xaml](https://github.com/microsoft/microsoft-ui-xaml/blob/main/controls/dev/Materials/Acrylic/AcrylicBrush_themeresources.xaml). Documented:

| Brush | Mode | Tint color | Tint opacity | Luminosity opacity | Fallback |
|---|---|---|---|---|---|
| `AcrylicBackgroundFillColorDefaultBrush` | Light | `#FCFCFC` | 0.0 | 0.85 | `#F9F9F9` |
| `AcrylicBackgroundFillColorDefaultBrush` | Dark | `#2C2C2C` | 0.15 | 0.96 | `#2C2C2C` |
| `AcrylicBackgroundFillColorBaseBrush` | Light | `#F3F3F3` | 0.0 | 0.90 | `#EEEEEE` |
| `AcrylicBackgroundFillColorBaseBrush` | Dark | `#202020` | 0.5 | 0.96 | `#1C1C1C` |

The in-app brushes (`AcrylicInAppFillColor...`) carry the same values.

Read plainly: in Light, the glass takes 85% of its lightness from a near-white and only 15% from the wallpaper. In Dark, 96% from a near-black and 4% from the wallpaper. Hue and saturation still come through, which is why it reads as glass and not as paint.

**When no luminosity opacity is given**, the code derives one. Documented in `AcrylicBrush.cpp`:

- The luminosity color's brightness (HSV value) is clamped to between 0.125 and 0.965. The glass is never pure black or pure white.
- Luminosity opacity is mapped from the tint opacity into the range 0.15 to 1.03, capped at 1.
- The tint opacity is scaled down by a modifier: 100% becomes 45% for pure white, 85% for pure black and 90% for mid gray. The effect fades out as the tint gets more saturated.

**Fallback.** Acrylic becomes its solid `FallbackColor` when the user turns off Transparency effects, in Battery Saver, on low-end hardware and, for background acrylic, when the window is inactive. In High Contrast the user's chosen background color replaces it. Source: [Acrylic material](https://learn.microsoft.com/en-us/windows/apps/design/style/acrylic), section "Usability and adaptability".

**Text.** "We've optimized the acrylic resources such that text meets contrast ratios on top of acrylic." Two rules follow: do not place accent-colored text on acrylic, and avoid hyperlinks on it. Same page, section "Legibility considerations".

## Windows: Mica

Mica is the material for long-lived windows. It is "an opaque, dynamic material that incorporates theme and desktop wallpaper". It "only samples the desktop wallpaper once". Source: [Mica material](https://learn.microsoft.com/en-us/windows/apps/design/style/mica).

**Not published:** the blur radius, tint color, tint opacity and luminosity opacity. `MicaController` exposes `TintColor`, `TintOpacity`, `LuminosityOpacity` and `FallbackColor`, but the API pages state no default values ([LuminosityOpacity](https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.composition.systembackdrops.micacontroller.luminosityopacity), [TintOpacity](https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.composition.systembackdrops.micacontroller.tintopacity)). The controller is not in the open WinUI repo. What the property names do show is that Mica uses the same tint plus luminosity model as Acrylic.

**Documented:**

- **Fallback.** Mica turns into `SolidBackgroundFillColorBase`, and Mica Alt into `SolidBackgroundFillColorBaseAlt`, when transparency is off, in Battery Saver, on low-end hardware and when the window is inactive. The values, from [Common_themeresources_any.xaml](https://github.com/microsoft/microsoft-ui-xaml/blob/main/controls/dev/CommonStyles/Common_themeresources_any.xaml):

  | Resource | Light | Dark |
  |---|---|---|
  | `SolidBackgroundFillColorBase` | `#F3F3F3` | `#202020` |
  | `SolidBackgroundFillColorBaseAlt` | `#DADADA` | `#0A0A0A` |

- **Content never sits on raw Mica.** Mica is the base layer and shows mainly in the title bar. Content goes on a content layer filled with `LayerFillColorDefaultBrush`, "a low-opacity solid color". Same file:

  | Resource | Light | Dark |
  |---|---|---|
  | `LayerFillColorDefault` (content over Mica) | white at 50% (`#80FFFFFF`) | `#3A3A3A` at 30% (`#4C3A3A3A`) |
  | `LayerOnMicaBaseAltFillColorDefault` (command bar over Mica Alt) | white at 70% (`#B3FFFFFF`) | `#3A3A3A` at 45% (`#733A3A3A`) |
  | `LayerOnAcrylicFillColorDefault` | white at 25% (`#40FFFFFF`) | white at 3.5% (`#09FFFFFF`) |

- **Dark mode** has its own configuration. The controller "reacts to the system Light and Dark themes by default", and once an app sets any of the four properties it must supply both sets itself. Source: [Apply Mica or Acrylic materials](https://learn.microsoft.com/en-us/windows/apps/develop/ui/system-backdrops).

**Smoke** is the third Windows material: a dim layer under modal dialogs. It is "always translucent black in both light and dark mode" ([Materials](https://learn.microsoft.com/en-us/windows/apps/design/signature-experiences/materials)). `SmokeFillColorDefault` is black at 30% (`#4D000000`) in both modes.

## macOS: materials and vibrancy

Apple publishes how the system behaves and which material to pick. It publishes no blur radius, tint, opacity or saturation value for any material. All of those are **not published**.

**Documented behavior:**

- A material is not plain opacity. It "uses a platform-specific blending that produces an effect that resembles heavily frosted glass". "The degree to which the background colors pass through depends on the thickness. The effect also varies with light and dark appearance." Source: [SwiftUI Material](https://developer.apple.com/documentation/swiftui/material).
- Thickness is a named scale, not a number: `ultraThin` ("mostly translucent"), `thin`, `regular` ("somewhat translucent"), `thick` ("more opaque than translucent"), `ultraThick` ("mostly opaque"). Same page.
- AppKit materials are picked by job, not by look: `titlebar`, `sidebar`, `menu`, `popover`, `headerView`, `sheet`, `hudWindow`, `windowBackground`, `contentBackground` and others. `windowBackground` and `contentBackground` are described as the backgrounds of opaque windows and opaque content. "Don't select materials based on the apparent colors they impart on your interface." Source: [NSVisualEffectView](https://developer.apple.com/documentation/appkit/nsvisualeffectview) and [NSVisualEffectView.Material](https://developer.apple.com/documentation/appkit/nsvisualeffectview/material-swift.enum).
- Two blending modes: behind-window (the desktop shows through, used for sheets and popovers) and within-window (scrolled content shows through, used for toolbars). Source: NSVisualEffectView.

**How text stays readable: vibrancy.** Vibrancy is "a subtle blending of foreground and background colors to increase the contrast and make the foreground content stand out". The rules around it:

- Use the built-in label colors (`labelColor`, `secondaryLabelColor`, `tertiaryLabelColor`, `quaternaryLabelColor`). They are a ladder of contrast, most to least.
- "Vibrancy works best when your custom views contain grayscale content." Colored text over colored glass can cancel out. Source: NSVisualEffectView.
- "Thicker materials, which are more opaque, can provide better contrast for text and other elements with fine features." Avoid the weakest label level on the `thin` and `ultraThin` materials "because the contrast is too low". Source: [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials).
- The floor is the usual one: contrast "no lower than 4.5:1", and 7:1 to aim for with custom colors in small text. Source: [HIG Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode).

**Liquid Glass** (the 2025 material, for controls and navigation only):

- It sits in a layer above content. "Don't use Liquid Glass in the content layer."
- The **regular** variant "blurs and adjusts the luminosity of background content to maintain legibility of text". Use it "when background content might create legibility issues, or when components have a significant amount of text, such as alerts, sidebars, or popovers".
- The **clear** variant is for small controls over photos and video. Over bright content, "consider adding a dark dimming layer of 35% opacity". This is the one number Apple gives.
- "Liquid Glass appears more opaque in larger elements like sidebars to preserve legibility over complex backgrounds."
- Small bars flip between a light and a dark look depending on what is under them, and their text is monochrome by default.

Sources: [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials) and [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color), section "Liquid Glass color".

**visionOS** states the clamp idea outright: glass "limits the range of background color information so a window can continue to provide contrast for app content". Source: HIG Materials.

**Fallback.** With Reduce Transparency on, "don't use semitransparent backgrounds in the user interface. For example, use only opaque windows." Source: [accessibilityDisplayShouldReduceTransparency](https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayshouldreducetransparency). Increase Contrast is a separate setting that asks for "a less subtle color palette or bolder lines" ([accessibilityDisplayShouldIncreaseContrast](https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayshouldincreasecontrast)).

## KDE: KWin blur and the Plasma theme

KDE splits the job. KWin blurs and adjusts what is behind a window. The Plasma theme supplies the tint as a translucent SVG.

**KWin blur defaults**, from [blur.kcfg](https://invent.kde.org/plasma/kwin/-/blob/master/src/plugins/blur/blur.kcfg). Documented:

| Setting | Default | Range in the settings page |
|---|---|---|
| `BlurStrength` | 15 | 1 to 15 |
| `NoiseStrength` | 5 | 0 to 14 |
| `Saturation` | 150 (percent) | 100 to 500 |

- The blur is a downsample and upsample chain, not a Gaussian, so strength 15 has no pixel radius. It selects the fourth downsample level (one sixteenth size) with the largest offset. Source: `initBlurStrengthValues` in [blur.cpp](https://invent.kde.org/plasma/kwin/-/blob/master/src/plugins/blur/blur.cpp).
- Noise is a 256 by 256 grayscale texture where each pixel is a random value below the noise strength, out of 255. At the default that is at most 4 of 255, under 2%. Same file, `ensureNoiseTexture`.
- Saturation is a standard luma-weighted color matrix (0.2126, 0.7152, 0.0722) applied to the blurred backdrop. The 150% default landed in KWin 6.6 (commit `3ce5b328`, "plugins/blur: Use 150% saturation by default").

**The older Background Contrast effect.** Until June 2025 a second KWin effect changed the backdrop's contrast, intensity and saturation with a color matrix. Its API doc says it exists "in order to improve the contrast and readability of any text in the translucent window" ([kwindoweffects.h](https://invent.kde.org/frameworks/kwindowsystem/-/blob/master/src/kwindoweffects.h)). It was removed in 2025 and only saturation was kept, inside the blur effect. The Breeze theme set these values in libplasma 6.3. Documented:

| Theme | contrast | intensity | saturation |
|---|---|---|---|
| Breeze ([plasmarc](https://invent.kde.org/plasma/libplasma/-/blob/v6.3.0/src/desktoptheme/breeze/plasmarc)) | 0.2 | not set | 10 |
| Breeze Dark ([plasmarc](https://invent.kde.org/plasma/libplasma/-/blob/v6.3.0/src/desktoptheme/breeze-dark/plasmarc)) | 0.2 | 0.6 | 10 |

Contrast below 1 flattens the backdrop toward mid gray. Intensity scales brightness, so Breeze Dark also darkened the backdrop to 60%. That was KDE's version of the lightness clamp, and dark mode had its own value.

**Fallback.** A Plasma theme has a `translucent/` folder of images used "when background contrast and blur effect is supported" and an `opaque/` folder "for non-compositing environments". The theme code switches to the translucent set only while the blur effect is active. Sources: [Plasma theme details](https://develop.kde.org/docs/plasma/theme/theme-details/) and `updateKSvgSelectors` in [theme_p.cpp](https://invent.kde.org/plasma/libplasma/-/blob/master/src/plasma/private/theme_p.cpp).

**Not published as a number:** the tint opacity. It lives inside the Breeze SVG files and was not measured for this note.

## GNOME: Shell and libadwaita

GNOME mostly avoids the problem.

- **App windows are opaque.** libadwaita's window colors are solid: `--window-bg-color` is `#fafafb` in light and `#222226` in dark. Its docs define no translucent window surface. Source: [libadwaita CSS variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html).
- **The Shell blurs in one place**, the lock screen. Documented in [unlockDialog.js](https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/main/js/ui/unlockDialog.js): `BLUR_RADIUS = 90` (times the display scale factor) and `BLUR_BRIGHTNESS = 0.65`.
- The effect is [ShellBlurEffect](https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/main/src/shell-blur-effect.c). Its brightness step multiplies every color channel by the brightness value. There is no tint, no saturation boost and no noise. The same values apply in light and dark.
- **High contrast** is a separate preference that apps cannot turn off. It raises border opacity from 15% to 50% and dim text opacity from 55% to 90%. Sources: [libadwaita CSS variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html), section "Opacity", and [Styles and appearance](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/styles-and-appearance.html).

The GNOME answer to "readable over any wallpaper" is a very strong blur plus a flat 35% darkening, with white text on top, used only where little text is shown.

## What Hyaline can borrow

Hyaline today: Light chrome is white at alpha 0.30 and Dark chrome is smoke at 0.70. Panels are 0.93 and 0.80. A plain alpha tint lets the wallpaper's lightness through in proportion, so Light chrome passes 70% of any dark patch straight to the text. The points below are for the prototype ticket ([issue #31](https://github.com/mookeyj79/Hyaline/issues/31)).

1. **Add a lightness clamp. This is the main one.** Windows keeps only 15% of the wallpaper's lightness in Light and 4% in Dark, while keeping its hue. Borrowable numbers: luminosity opacity 0.85 (Light) and 0.96 (Dark), toward a near-white and a near-black. In a web prototype this is a color layer with `mix-blend-mode: luminosity` over the blurred wallpaper. Where only `backdrop-filter` is available, lowering contrast and shifting brightness after the blur does a similar job, as KDE's old effect did (contrast 0.2, intensity 0.6 in dark).
2. **Blur more.** Windows uses a Gaussian standard deviation of 30. Hyaline's check measures with 18 px. CSS `blur()` also takes a standard deviation, so 30 px is a like-for-like starting value. GNOME goes to 90 where it wants the wallpaper reduced to a mood.
3. **Boost saturation after the clamp**, so clamped glass does not go gray: 1.25 (old Acrylic) to 1.5 (KWin default).
4. **Noise is optional and small**: 2% (Windows), under 2% (KWin). It hides banding in the blur. It is decoration only if it is visible.
5. **Dark needs a denser recipe than Light.** Every system that publishes numbers does this: 0.96 against 0.85 on Windows, an extra 0.6 darkening in Breeze Dark. Hyaline already leans this way (0.70 against 0.30), but Light is far thinner than anything a vendor ships.
6. **Never pure black or white.** Acrylic clamps the glass's brightness to 0.125 to 0.965. This matches Hyaline's existing hard no.
7. **Keep the chrome and content split.** Both Apple and Microsoft do it. Liquid Glass is banned from the content layer. Mica shows in the title bar while content sits on a layer of white at 50% (Light) or dark gray at 30% (Dark). Windows also bans accent-colored text on Acrylic and Apple wants grayscale text on vibrant glass, which is Hyaline's "primary text and solid accent fills only" rule for chrome.
8. **Author the flat fallback, do not derive it from a wallpaper.** Windows names a solid color per material and per mode (`#F9F9F9` and `#2C2C2C` for Acrylic, `#F3F3F3` and `#202020` for Mica). Once the glass clamps lightness, the glass looks nearly the same over any wallpaper, so a fixed flat value is honest. Hyaline's pinned Light `panel_flat` is already this pattern. The fallback is also what users see with transparency off, so it is a first-class surface.
9. **A dim layer for the worst case.** Apple suggests black at 35% under clear glass over bright media. Windows Smoke is black at 30%. GNOME multiplies by 0.65. All three land in the same place.
10. **Consider a Mica-style option for long-lived windows.** Opaque, tinted by a heavily blurred wallpaper sampled once. It gives the "belongs to this desktop" feel with no readability risk, and it fits apps that cannot blur.

## Not verified

- **Apple's numbers.** No blur radius, tint, opacity or saturation for any macOS material or for Liquid Glass is published. Only the 35% dim layer is.
- **Mica's numbers.** Blur radius, tint and luminosity defaults are not in Microsoft Learn or in the open WinUI source.
- **Whether the Learn page or the code is current for Acrylic.** The page describes an exclusion layer. The `main` branch code uses a luminosity layer and leaves the exclusion and saturation constants unused. The shipped system compositor (for `DesktopAcrylicController`) is closed source and may differ again.
- **Breeze's tint opacity.** It is inside SVG files that were not opened.
- **GNOME and app-window blur.** The libadwaita docs define only opaque window colors. Mutter's source was not searched for a blur protocol.
- **CSS `blur()` units.** Stated from the Filter Effects spec from memory. The spec was not re-read for this note.

No host was blocked by the network policy. Apple's pages were read through their JSON endpoints (`developer.apple.com/tutorials/data/...`), and Microsoft Learn pages through their source repos (`MicrosoftDocs/windows-dev-docs`, `MicrosoftDocs/winapps-winrt-api`, `MicrosoftDocs/win32`).
