# What glass controls Full glass ports expose

Research for [issue #30](https://github.com/mookeyj79/Hyaline/issues/30), part of the map in [issue #28](https://github.com/mookeyj79/Hyaline/issues/28). Read on 2026-11-15.

Every claim links to the project's own docs. Where the docs are silent, the project's own source file is linked instead and marked "(source)". Anything neither covers is listed under [Not verified](#not-verified).

## Answer in brief

- **Opacity of the content background is the only control every translucent app has.** It is one number, and the tint is always the app's own background color.
- **Blur is on or off almost everywhere.** A port can set a blur radius only on macOS (kitty, WezTerm, Ghostty) and in CSS.
- **On Linux and Windows the blur belongs to the system, not the app.** KWin has one global blur setting. GNOME and Cinnamon blur only through a user-installed extension. Windows acrylic and Mica are fixed recipes.
- **Saturation, brightness, and contrast filters on the backdrop exist only in CSS `backdrop-filter`.** KWin has a global saturation slider, and two desktop extensions have their own, but no port file can set them.
- **Only Windows Terminal and CSS let chrome and content have different opacity.** Everywhere else the window has one opacity, or the title bar is drawn by the system.

So a glass recipe that must hold in every Full glass port can use one thing: a dense tint, set as background color plus opacity. Blur has to be treated as unknown, and readability has to pass with blur off.

## Summary table

"Port" means a file the port can ship. "System" means a setting the user changes by hand, outside the port.

| App | Opacity | Blur on/off | Blur radius | Tint | Saturation, brightness | Chrome and content differ | Platform limits |
|---|---|---|---|---|---|---|---|
| Windows Terminal | Port: `opacity` 0 to 100, per profile | Port: `useAcrylic` | No | Background color and opacity only | No | Yes: tab row takes `#rrggbbaa`, Mica, or acrylic at a fixed 50% | Unblurred opacity needs Windows 11. Mica needs build 22621. Active tab is always solid |
| GNOME Terminal | Port: only in patched builds (Ubuntu, Mint) | No setting | No | Background color and opacity only | No | No: frame is drawn by the GTK theme | Upstream has no transparency at all. Blur needs a desktop extension |
| VS Code | None native | None native | No | None native | No | No | Transparency was declined as out of scope |
| VS Code + Vibrancy Continued | Extension: `opacity` | Extension: `type` | No | Extension: background override color | Not listed, custom CSS can be imported | Through its themes and imported CSS | Patches VS Code files. Linux gets transparency only |
| GNOME Shell CSS | Port: alpha in colors | Not in CSS | Not in CSS | Port: any color with alpha | Not in CSS | Yes, per element | Blur needs Blur my Shell or extension code |
| Cinnamon CSS | Port: alpha in colors | Not in CSS | Not in CSS | Port: any color with alpha | Not in CSS | Yes, per element | Blur needs the Blur Cinnamon extension |
| KWin (Plasma) | Per app | System: Blur effect | System: one global strength | Per app | System: global saturation and noise | Not applicable | One setting for all apps. Apps can only ask for a blurred region |
| Konsole | Port: `Opacity` in the color scheme | Port: `Blur` in the color scheme | No, KWin's global value | Background color and opacity only | No | No | Blur needs KWin's Blur effect |
| kitty | Port: `background_opacity` | Port: `background_blur` | macOS only | Background color. `background_tint` is for its own background image only | No | No: title bar takes a solid color | Blur on macOS and on Wayland compositors with the blur extension |
| WezTerm | Port: `window_background_opacity` | Port: per platform setting | macOS only | Background color. Windows acrylic accent color only before build 22621 | Only on its own background image (`hsb`) | No documented alpha for the title bar | Windows: Acrylic, Mica, or Tabbed. Wayland blur needs the compositor |
| Alacritty | Port: `window.opacity` | Port: `window.blur` | No | Background color and opacity only | No | No | Blur on macOS and KDE Wayland only |
| Ghostty | Port: `background-opacity` | Port: `background-blur` | macOS only | Background color and opacity only | No | No: title bar matches the background or takes a solid color | Blur on macOS and KDE Plasma. KDE ignores the intensity |
| CSS `backdrop-filter` | Yes, per element | Yes | Yes: `blur(<length>)` | Yes: any background color with alpha | Yes: `saturate()`, `brightness()`, `contrast()` | Yes, per element | Filters page content behind the element, not the desktop behind the browser |

## What recipe is expressible where

**Lowest common denominator: tint color plus one opacity.** Every app above that can be translucent takes a background color and a single opacity number, and nothing more is shared. Blur is either missing, off by default, or owned by the system, so the recipe cannot depend on it. A clamp that lightens or darkens the backdrop is not available as a filter, but a dense tint does the same job: the denser the tint, the less the wallpaper can move the result.

**Middle: tint, opacity, and a blur switch.** Windows Terminal, Konsole, kitty, WezTerm, Alacritty, and Ghostty can each ask for blur. None of them can set the radius on Windows or Linux, and whether the blur appears depends on the OS version, the compositor, and user settings such as Windows "Transparency effects" or KWin's Blur effect.

**Best case: CSS.** `backdrop-filter` gives blur with a radius, `saturate()`, `brightness()`, and `contrast()`, on any element, with any tint over it. This is the only place the full recipe (blur, then a light or dark clamp, then a tint) can be written down. It covers the prototype page and any web port, but it filters the page behind the element, not the desktop.

**Chrome and content split.** Only Windows Terminal (tab row alpha separate from profile opacity) and CSS can give chrome a different opacity from content. GNOME Shell and Cinnamon themes can too, but there the whole theme is chrome. For every other terminal the split in ADR 0004 cannot be expressed.

**System-level controls a port cannot set.** KWin's blur strength, noise, and saturation, the pipelines in Blur my Shell, and the blur type, tint, and saturation in Blur Cinnamon are real controls, but they are user settings for the whole desktop. A port README can recommend values. A port file cannot carry them.

## Per app

### Windows Terminal

- `opacity` is a profile setting, an integer from 0 to 100. With `useAcrylic` true the background is blurred acrylic, with it false the opacity is unblurred. Unblurred opacity only works on Windows 11. [Appearance profile settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)
- There is no setting for blur radius, tint strength, saturation, or brightness on that page.
- `unfocusedAppearance` can hold its own `opacity`, `useAcrylic`, `background`, and background image settings, so focused and unfocused windows can differ. [Appearance profile settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)
- Whether an unfocused window keeps acrylic depends on the global `compatibility.enableUnfocusedAcrylic`. [Interaction settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/interaction)
- `window.useMica` puts Mica under the whole window, on builds 22621 and later. It shows wherever a layer above has alpha, including under terminal panes with `opacity` below 100. The docs say: "It is not currently possible to have an unblurred transparent background for the Terminal and a Mica background for the tabs / tab row simultaneously." [Theme settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/themes)
- `tabRow.background` and `tabRow.unfocusedBackground` take `#rrggbbaa`, so the tab row has its own alpha. `tab.background` is "always treated as a solid color". An inactive tab set to `terminalBackground` or `accent` gets a fixed 30% alpha. [Theme settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/themes)
- `useAcrylicInTabRow` is a global switch that gives the tab row "an acrylic background at 50% opacity". The percentage is fixed. [Appearance global settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/appearance)
- Background image: `backgroundImage` (a path, or `desktopWallpaper`), `backgroundImageOpacity` 0 to 1, `backgroundImageStretchMode`, and `backgroundImageAlignment`. There is no blur or tint setting for the image. [Appearance profile settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)
- Windows itself turns acrylic off in Battery Saver mode and when the user turns off Transparency effects. Mica falls back to a solid color in the same cases. [Acrylic material](https://learn.microsoft.com/en-us/windows/apps/design/style/acrylic), [Mica material](https://learn.microsoft.com/en-us/windows/apps/design/style/mica)
- The acrylic recipe is fixed by Windows: "background, blur, exclusion blend, color/tint overlay, noise". [Acrylic material](https://learn.microsoft.com/en-us/windows/apps/design/style/acrylic)

### GNOME Terminal

- Upstream has no transparency. The settings schema has no key for transparency, opacity, or blur. [org.gnome.Terminal.gschema.xml](https://gitlab.gnome.org/GNOME/gnome-terminal/-/blob/master/src/org.gnome.Terminal.gschema.xml) (source)
- Ubuntu's build patches it back in with three keys: `use-transparent-background`, `background-transparency-percent` (0 opaque to 100 fully transparent), and `use-theme-transparency`. [0001-Restore-transparency.patch](https://git.launchpad.net/ubuntu/+source/gnome-terminal/plain/debian/patches/0001-Restore-transparency.patch) (source)
- There is no blur setting in either. Blur behind the window has to come from the desktop: Blur my Shell on GNOME or Blur Cinnamon on Cinnamon, both below.
- The tint is the profile background color at that one transparency. The window frame and tab bar are drawn by the GTK theme, so chrome cannot get its own opacity from the profile.

### VS Code

- No native transparency or blur. The request "Allow for transparent / vibrant window theme" was closed in 2017 with the `*out-of-scope` label. [vscode issue 32257](https://github.com/microsoft/vscode/issues/32257)
- Theme colors accept an alpha channel (`#RRGGBBAA`), but the reference lists no window opacity or blur setting. [Theme Color reference](https://code.visualstudio.com/api/references/theme-color)
- Electron, which VS Code is built on, has the window options (`transparent`, `vibrancy` on macOS, `backgroundMaterial` on Windows with `mica`, `acrylic`, or `tabbed`), but VS Code does not expose them. [Electron BaseWindow options](https://www.electronjs.org/docs/latest/api/structures/base-window-options)

Vibrancy Continued, a third-party extension ([README](https://github.com/illixion/vscode-vibrancy-continued/blob/main/README.md)):

- `vscode_vibrancy.type`: `transparent` (no blur, the Linux default), `acrylic`, `acrylic-classic`, `mica`, `tabbed` on Windows, and the macOS materials. Mica and Tabbed are Windows 11 only.
- `vscode_vibrancy.opacity`: -1 to 1, where 0 is the most transparent and 1 removes transparency.
- `vscode_vibrancy.backgroundOverride`: a color that replaces the theme background for the effect.
- `vscode_vibrancy.theme` picks one of its built-in themes, and `vscode_vibrancy.imports` loads the user's own CSS or JS files.
- No blur radius, saturation, or brightness setting is listed.
- Linux: "transparency only, blur requires a compositor such as KWin, Hyprland, or Picom".
- Risk: the README says it "works by editing VS Code's workbench HTML", a file VS Code checksums at startup, and that it rewrites the stored checksum to hide the warning. VS Code's own FAQ says a patched install shows `[Unsupported]` and "patching VS Code means you are running an unsupported version", and that the patch lasts "until the next update". [VS Code FAQ](https://code.visualstudio.com/docs/supporting/faq)
- Flatpak and read-only installs are "currently unsupported".

### GNOME Shell CSS

- Shell themes are CSS read by St. Colors can carry alpha, so any element can be a translucent tint.
- St's CSS parser has no `backdrop-filter` and no blur property. The only blur it reads is the blur of a shadow. [st-theme-node.c](https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/main/src/st/st-theme-node.c) (source)
- The Shell does have a blur effect for code, not CSS: `Shell.BlurEffect`, with `radius`, `brightness`, and `mode` (actor or background). An extension can use it. A theme cannot. [Shell.BlurEffect](https://gnome.pages.gitlab.gnome.org/gnome-shell/shell/class.BlurEffect.html)
- Blur my Shell, a third-party extension, blurs the panel, dock, overview, popups, and application windows. Each part uses a pipeline of effects: blur, "color and luminosity", noise, and others. It supports GNOME Shell 46 to 51. These are the extension's own settings. [Blur my Shell README](https://github.com/aunetx/blur-my-shell/blob/master/README.md)

### Cinnamon CSS

- Cinnamon themes use Cinnamon's fork of St. Its parser also has no `backdrop-filter`. [st-theme-node.c](https://github.com/linuxmint/cinnamon/blob/master/src/st/st-theme-node.c) (source)
- Cinnamon's own settings schema has no blur or transparency key. [org.cinnamon.gschema.xml](https://github.com/linuxmint/cinnamon/blob/master/data/org.cinnamon.gschema.xml) (source)
- Blur Cinnamon, a third-party extension, can "Blur, Tint, Desaturate and make transparent" panels, menus, notifications, and application window backgrounds. It has several blur types with a configurable intensity, a tint with color and intensity, a saturation control, and an opacity control for application windows. Most components are off by default. It needs Cinnamon 6.0 or later, and Wayland support is experimental. [Blur Cinnamon README](https://github.com/linuxmint/cinnamon-spices-extensions/blob/master/BlurCinnamon%40klangman/README.md)

### KDE: KWin and Konsole

- KWin's Blur effect has three global settings: blur strength, noise strength, and saturation. [blur.kcfg](https://invent.kde.org/plasma/kwin/-/blob/master/src/plugins/blur/blur.kcfg), [blur_config.ui](https://invent.kde.org/plasma/kwin/-/blob/master/src/plugins/blur/blur_config.ui) (source)
- An app can only ask KWin to blur a region behind its surface. The protocol has no radius or strength argument. [blur.xml](https://invent.kde.org/libraries/plasma-wayland-protocols/-/blob/master/src/protocols/blur.xml) (source)
- The cross-desktop Wayland protocol is the same shape: `set_blur_region` and a `blur` capability, nothing else. It is marked as in the testing phase. [ext-background-effect-v1](https://wayland.app/protocols/ext-background-effect-v1)
- Ghostty's docs confirm the limit from the app side: "KWin ... only has one global blur setting and does not allow applications to specify individual blur settings." [Ghostty config reference](https://ghostty.org/docs/config/reference)
- Konsole's color scheme editor has "Blur background", "Background color transparency", and "Wallpaper transparency". [ColorSchemeEditor.ui](https://invent.kde.org/utilities/konsole/-/blob/master/src/colorscheme/ColorSchemeEditor.ui) (source)
- They are stored in the color scheme file as `Opacity` (0 to 1), `Blur` (true or false), `Wallpaper`, and `WallpaperOpacity`. So a Konsole port can ship both in one file. [ColorScheme.cpp](https://invent.kde.org/utilities/konsole/-/blob/master/src/colorscheme/ColorScheme.cpp) (source)
- The Konsole handbook does not describe these settings. It only lists the `--notransparency` option. [Konsole handbook source](https://invent.kde.org/utilities/konsole/-/blob/master/doc/manual/index.docbook)

### kitty

All from [kitty.conf](https://sw.kovidgoyal.net/kitty/conf/):

- `background_opacity`: 0 to 1. It applies only to cells that have the default background color. `transparent_background_colors` adds up to 7 more colors, each with its own opacity.
- `background_blur`: a positive value turns blur on. "On macOS, this will also control the blur radius". It is "Currently supported on macOS and Wayland, when the compositor supports the background blur extension". It only takes effect when `background_opacity` is below 1.
- `background_tint` and `background_tint_gaps` tint kitty's own `background_image` with the background color. They do not apply to the desktop behind the window.
- No saturation or brightness setting for the backdrop.
- `macos_titlebar_color` and `wayland_titlebar_color` take `system`, `background`, or a color. No alpha is documented.
- The docs advise that with a low opacity you "set the background color to a color the matches the general color of the desktop background, for best text rendering".

### WezTerm

- `window_background_opacity`: 0 to 1. [window_background_opacity](https://wezterm.org/config/lua/config/window_background_opacity.html)
- `text_background_opacity`: the alpha for cell backgrounds that are not the default background. [Colors and appearance](https://wezterm.org/config/appearance.html)
- macOS: `macos_window_background_blur` is a blur radius. [macos_window_background_blur](https://wezterm.org/config/lua/config/macos_window_background_blur.html)
- Windows: `win32_system_backdrop` is `Auto`, `Disable`, `Acrylic`, `Mica`, or `Tabbed`. Mica and Tabbed need build 22621. Opacity must be below 1 for it to show. [win32_system_backdrop](https://wezterm.org/config/lua/config/win32_system_backdrop.html)
- Windows tint: `win32_acrylic_accent_color` only works before build 22621. "More recent versions of Windows do not permit configuring the accent color for Acrylic". [win32_acrylic_accent_color](https://wezterm.org/config/lua/config/win32_acrylic_accent_color.html)
- Wayland: `wayland_window_background_blur` is true or false. "Wayland compositors may need to have blur enabled explicitly." [wayland_window_background_blur](https://wezterm.org/config/lua/config/wayland_window_background_blur.html). The older `kde_window_background_blur` is nightly only and deprecated. [kde_window_background_blur](https://wezterm.org/config/lua/config/kde_window_background_blur.html)
- Saturation and brightness exist only for WezTerm's own background image layers: `hsb` multiplies hue, saturation, and brightness, and each layer has an `opacity`. [background](https://wezterm.org/config/lua/config/background.html), [window_background_image_hsb](https://wezterm.org/config/lua/config/window_background_image_hsb.html)
- Chrome: `window_frame` sets title bar and tab bar colors. No alpha is documented. [window_frame](https://wezterm.org/config/lua/config/window_frame.html)

### Alacritty

All from [the Alacritty config reference](https://alacritty.org/config-alacritty.html):

- `window.opacity`: 0.0 to 1.0.
- `window.blur`: true or false, "works on macOS/KDE Wayland". It asks the compositor to blur.
- `colors.transparent_background_colors`: whether the opacity applies to every cell background or only the default one.
- Nothing else: no radius, tint, filter, or chrome setting.

### Ghostty

All from [the Ghostty config reference](https://ghostty.org/docs/config/reference):

- `background-opacity`: 0 to 1. On macOS it is turned off in native fullscreen.
- `background-opacity-cells`: also apply the opacity to cells with their own background color.
- `background-blur`: `true`, `false`, or a blur intensity (the default for `true` is 20). On macOS 26 and later, `macos-glass-regular` and `macos-glass-clear` use the native glass effects.
- Blur is "Supported on macOS and on some Linux desktop environments, including: KDE Plasma (Wayland and X11)". On KDE "the exact blur intensity is ignored". "All other Linux desktop environments are as of now unsupported."
- `background-image` and `background-image-opacity` are Ghostty's own image, not the desktop.
- No tint, saturation, or brightness setting for the backdrop.
- Chrome: on macOS, `macos-titlebar-style` set to `transparent` or `tabs` makes the title bar match the terminal background. On GTK, `window-titlebar-background` takes a hex color with no alpha.

### Browser CSS `backdrop-filter`

- `backdrop-filter` takes a list of filter functions: `blur()`, `brightness()`, `contrast()`, `drop-shadow()`, `grayscale()`, `hue-rotate()`, `invert()`, `opacity()`, `saturate()`, and `sepia()`, or an SVG filter. They can be chained, for example `blur(4px) saturate(150%)`. [MDN: backdrop-filter](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter)
- It applies to "the pixels painted behind an element, up to the nearest ancestor that is a backdrop root". A parent with `opacity` below 1, a `filter`, a mask, or its own `backdrop-filter` is a backdrop root and stops the effect from reaching what is behind it. [MDN: backdrop-filter](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter)
- The tint is the element's own background color with alpha, drawn over the filtered backdrop. Each element has its own, so chrome and content can differ freely.
- It filters content in the page. It does not reach the desktop behind the browser window.
- Support: Chrome 76, Edge 79, Firefox 103, Safari 18 unprefixed (Safari 9 with `-webkit-`). [MDN browser compat data](https://github.com/mdn/browser-compat-data/blob/main/css/properties/backdrop-filter.json)
- The property is defined in Filter Effects Module Level 2, still an Editor's Draft. [Filter Effects Module Level 2](https://drafts.csswg.org/filter-effects-2/)

## Not verified

- **Acrylic tint in Windows Terminal.** The docs do not say how the profile `background` color and `opacity` map onto the acrylic tint layer, or what the blur radius is.
- **`compatibility.enableUnfocusedAcrylic` default.** The docs page says false. The [settings schema](https://github.com/microsoft/terminal/blob/main/doc/cascadia/profiles.schema.json) in the Windows Terminal repo says true.
- **Mutter and the Wayland blur protocol.** No GNOME doc read here says whether Mutter supports `ext-background-effect-v1` or any other way for an app to ask for blur. kitty and WezTerm only say "when the compositor supports" it.
- **Which Plasma release added KWin's saturation setting.** It is in the `master` branch. The release was not checked.
- **Blur on X11 for kitty, WezTerm, and Alacritty.** Their docs list macOS, Windows, and Wayland only. Ghostty is the one that names KDE on X11.
- **Which WezTerm release has `wayland_window_background_blur`.** The page gives no version. The option it replaces is marked nightly only.
- **Alpha in title bar colors** for kitty, WezTerm, and Ghostty. The docs show solid colors and do not say whether alpha is accepted.
- **Whether a theme can turn on or configure Blur my Shell or Blur Cinnamon.** Both READMEs describe user preferences only. Neither describes a way for a theme to set them.
- **Vibrancy Continued's built-in themes.** What each one changes (for example the "Only Subbar" themes) was not read beyond their names.
- **Nothing here was tested on a real machine.** This is a reading of docs and source files only.
- The network blocked no host. `docs.kde.org` returned 404 for the Konsole handbook pages tried, so the handbook was read from its source file in the Konsole repo.
