# Which opacity-only ports exist, and what each app offers

Research for [issue #88](https://github.com/mookeyj79/Hyaline/issues/88), part of the map in [issue #86](https://github.com/mookeyj79/Hyaline/issues/86). Read on 2026-11-17.

Opacity-only glass, as GLOSSARY.md defines it: translucent surfaces in an app that offers a tint and a single opacity, with no clamp. Blur, if any, is not counted. This note builds on the earlier glass controls research (issue #30, tag `archive/research/port-glass-controls`) and does not repeat its terminal survey (kitty, WezTerm, Alacritty, Ghostty, Konsole), since none of those is a Hyaline port or a planned one.

Every claim links to the app's own docs. Where the docs are silent, the app's own source file is linked and marked "(source)". Anything neither covers is under [Not verified](#not-verified).

## Answer in brief

- **Two ports are opacity-only glass today: Windows Terminal and GNOME Terminal.** Both are Tier 1.
- **One more port draws opacity-only surfaces without being a glass port:** Cinnamon (Tier 2) keeps the translucent `panel` on the lock screen and desklets.
- **The preview falls back to opacity-only glass** when the browser has no `backdrop-filter`.
- **One planned port could be opacity-only:** GTK and MATE, where CSS colors take alpha but there is no backdrop filter. Obsidian has a translucent window switch, but what a theme controls under it is not documented.
- **No app in the list lets a port set a blur radius.** Blur is an on/off request (Windows Terminal), or comes from the desktop (GNOME Terminal, Cinnamon, GTK), or does not exist.
- **Only Windows Terminal has two opacities**, one for the terminal area and one for the tab row. Everywhere else the window has one, or (Cinnamon, GTK) each element has its own alpha.
- **Every default is opaque.** Windows Terminal ships at `opacity` 100. Ubuntu's GNOME Terminal ships with transparency off, and a slider at 50 percent when it is turned on.

## Summary table

| Port | Status | Opacity | Tint | Blur | App default | OS or compositor conditions |
|---|---|---|---|---|---|---|
| Windows Terminal | Tier 1, opacity-only | Two: profile `opacity` (panel) and tab row `#rrggbbaa` alpha (chrome) | Free: profile background and tab row color | On/off: `useAcrylic` for the terminal, `useMica` for the window. No radius | `opacity` 100, `useAcrylic` false, `useMica` false | Unblurred opacity needs Windows 11. Mica needs build 22621. Acrylic and Mica turn off with Transparency effects off or Battery Saver |
| GNOME Terminal | Tier 1, opacity-only | One per profile: `background-transparency-percent` | Free: profile background | None in the app. Desktop extension only | Transparency off. Slider 50. "Use theme transparency" on | Only in builds that carry Ubuntu's patch |
| Cinnamon | Tier 2, translucent in places | Per element: alpha in CSS colors | Free: any color | None in CSS. Blur Cinnamon extension is a user setting | None (the theme sets it) | Cinnamon desktop only |
| Preview | Clamp glass, opacity-only fallback | Per element | Free | `backdrop-filter` with a radius, when the browser has it | Not applicable | Fallback only where `backdrop-filter` is missing |
| GTK and MATE (planned) | Candidate | Per element: alpha in CSS colors, plus `opacity` | Free | No `backdrop-filter` in GTK CSS | None (the theme sets it) | See the open questions below |
| Obsidian (planned) | Unclear | Not documented | Not documented | Not documented | Not stated | Not supported on Linux |

The other ports and planned ports have no glass of their own. They are listed under [No glass of their own](#no-glass-of-their-own).

## Existing ports

### Windows Terminal

- **Panel opacity.** `opacity` is a profile setting, "an integer value from 0-100, representing a 'percent opaque'". Default `100`. [Appearance profile settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)
- It is per profile, not per color scheme, so one value serves both variants. `unfocusedAppearance` accepts its own `opacity` and `useAcrylic`, so focused and unfocused windows can differ. [Appearance profile settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)
- **Blur.** `useAcrylic`, true or false, default `false`. "When `useAcrylic` is set to `true`, the window will use the acrylic material to create a blurred background ... When `useAcrylic` is set to false, the terminal will use an unblurred opacity." No radius setting. [Appearance profile settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)
- "Unblurred opacity (`"useAcrylic": false`) only works on Windows 11." [Appearance profile settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)
- **Panel tint.** The profile or scheme `background`, `#rgb` or `#rrggbb`, no alpha. The alpha comes from `opacity`. [Appearance profile settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)
- **Chrome opacity.** Theme colors accept `#rrggbbaa`, so `tabRow.background` and `tabRow.unfocusedBackground` carry their own alpha. [Theme settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/themes)
- The tab row only shows something through that alpha when `window.useMica` is on. Mica sits "beneath all other UI layers". Default `false`. "Mica is only available on Windows builds >= 22621." So the chrome alpha lays the tint over Mica, a blurred system material, not over the raw wallpaper. [Theme settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/themes)
- "It is not currently possible to have an unblurred transparent background for the Terminal and a Mica background for the tabs / tab row simultaneously." [Theme settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/themes)
- The active and inactive tab colors are "always treated as a solid color". An inactive tab set to `terminalBackground` or `accent` gets a fixed 30 percent alpha. [Theme settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/themes)
- Windows turns acrylic off in Battery Saver and when Transparency effects is off. Mica falls back to a solid color in the same cases. [Acrylic material](https://learn.microsoft.com/en-us/windows/apps/design/style/acrylic), [Mica material](https://learn.microsoft.com/en-us/windows/apps/design/style/mica)
- The port today: scheme `background` is the `panel` tint, `opacity` is the `panel` alpha in percent, the tab row is `chrome` with its alpha, the active tab is `panel_flat`. One `opacity` serves both variants, so the README uses Light's denser value. (`Ports/windows-terminal/MAPPING.md`)

### GNOME Terminal

- **Upstream has no transparency.** The settings schema has no transparency, opacity, or blur key. [org.gnome.Terminal.gschema.xml](https://gitlab.gnome.org/GNOME/gnome-terminal/-/blob/master/src/org.gnome.Terminal.gschema.xml) (source)
- **Ubuntu's patch adds three profile keys.** [0001-Restore-transparency.patch](https://git.launchpad.net/ubuntu/+source/gnome-terminal/plain/debian/patches/0001-Restore-transparency.patch) (source)
  - `use-transparent-background`, default `false`.
  - `background-transparency-percent`, default `50`: "A value between 0 and 100, where 0 is opaque and 100 is fully transparent."
  - `use-theme-transparency`, default `true`: use the GTK theme's `TerminalScreen-background-darkness` value, if available, instead of the slider.
- **One opacity per profile.** The window frame and tab bar are drawn by the GTK theme, so chrome has no opacity of its own here.
- **Tint** is the profile background color.
- **Blur.** None in either build. Blur behind the window comes from the desktop, through Blur my Shell on GNOME or Blur Cinnamon on Cinnamon. See the glass controls research (#30) for those extensions.
- The port today: `use-transparent-background` on, `use-theme-transparency` off, and the slider at 100 minus the `panel` alpha in percent. (`Ports/gnome-terminal/MAPPING.md`)

### Cinnamon

- Cinnamon shell themes are CSS read by Cinnamon's fork of St. Colors take alpha, so any element can be a translucent tint with its own alpha. The parser has no `backdrop-filter`. [st-theme-node.c](https://github.com/linuxmint/cinnamon/blob/master/src/st/st-theme-node.c) (source)
- Cinnamon's own settings schema has no blur or transparency key. [org.cinnamon.gschema.xml](https://github.com/linuxmint/cinnamon/blob/master/data/org.cinnamon.gschema.xml) (source)
- Blur Cinnamon, a third-party extension, adds blur with a configurable intensity, a tint, saturation, and window opacity. These are user settings, not theme settings. [Blur Cinnamon README](https://github.com/linuxmint/cinnamon-spices-extensions/blob/master/BlurCinnamon%40klangman/README.md)
- So Cinnamon is opacity-only per element, with no default (the theme sets every alpha). The port is Tier 2 but keeps translucent `panel` on the lock screen and desklets, and uses `raised_flat` for raised surfaces. Those surfaces fall under any rule the map sets for opacity-only glass. (`Ports/cinnamon/MAPPING.md`)

### Preview

- The preview page uses the CSS clamp where `backdrop-filter` exists. Without it (checked with `@supports`) chrome and panel fall back to the dense tint alone, which is opacity-only glass with a separate alpha per surface. (`Ports/preview/MAPPING.md`)
- `backdrop-filter` support: Chrome 76, Edge 79, Firefox 103, Safari 18 unprefixed. So the fallback is rare in practice. [MDN browser compat data](https://github.com/mdn/browser-compat-data/blob/main/css/properties/backdrop-filter.json)

## Planned ports

### GTK and MATE

- GTK 4 CSS accepts `rgb()`, `rgba()`, and `hsl()` colors, and has `opacity` and `filter`. It has no `backdrop-filter`. [GTK CSS properties](https://docs.gtk.org/gtk4/css-properties.html)
- So a GTK theme can give each element a tint and its own alpha, with no clamp and no blur: opacity-only per element, like Cinnamon.
- Whether a translucent window background shows the desktop, rather than black or the window below, depends on the compositor and on the app. The GTK docs read here do not say. See [Not verified](#not-verified).

### Obsidian

- **Settings > Appearance > Advanced** has "Translucent window": "Turn on translucency effect to enhance a sense of depth. Best used with dark mode. Not supported on Linux." [Obsidian settings](https://obsidian.md/help/settings)
- The page lists no opacity or blur setting and does not state the default. How the switch combines with a theme's CSS background colors is not documented.

### Windows (system theme)

- Not opacity-only. Windows has "Transparency effects", on or off: "These effects make some window backgrounds and surfaces appear slightly transparent with an acrylic blur." No opacity slider. [Change colors in Windows](https://support.microsoft.com/en-us/windows/change-colors-in-windows-d26ef4d6-819a-581c-1581-493cfcc005fe)
- The tint on Start and the taskbar is the accent color, and only "if you select dark or custom as your Windows color mode". [Change colors in Windows](https://support.microsoft.com/en-us/windows/change-colors-in-windows-d26ef4d6-819a-581c-1581-493cfcc005fe)
- The acrylic recipe itself is fixed by Windows. [Acrylic material](https://learn.microsoft.com/en-us/windows/apps/design/style/acrylic)

### StartAllBack

- Its home page mentions "dynamic translucency" for the taskbar, "rounded acrylic menus", and recoloring the UI. It publishes no settings documentation, so whether it offers an opacity number or a tint is unknown. [StartAllBack](https://www.startallback.com/)

### Neovim

- `winblend` (floating windows) and `pumblend` (popup menu) set "pseudo-transparency", 0 opaque to 100 transparent, default `0`. "UI-dependent. Works best with RGB colors. 'termguicolors'". [Neovim options](https://neovim.io/doc/user/options.html)
- This blends a float over the editor text behind it, not over the desktop. It is not Hyaline glass. The editor background itself takes the terminal's glass when the theme leaves it unset.

### Homepage, Jellyfin, theme.park

- These are web pages, so they have CSS `backdrop-filter`, the clamp family, not opacity-only. What sits behind a surface is the page's own content, not the desktop.
- Homepage's `background` setting takes Tailwind `blur`, `saturate`, and `brightness` values and an `opacity` of 0 to 100 for its background image. `cardBlur` blurs the cards and "is incompatible with the background blur, saturate and brightness filters." [Homepage settings](https://gethomepage.dev/configs/settings/)
- Jellyfin's custom CSS "is only applied to clients that use Jellyfin Web." [Jellyfin CSS customization](https://jellyfin.org/docs/general/clients/css-customization/)
- theme.park's docs list the apps it themes but say nothing about transparency or blur. [theme.park docs](https://docs.theme-park.dev/)

## No glass of their own

- **Run inside a terminal:** Starship, Claude Code, Zsh, Bash, bat, eza, fzf, K9s, tmux, GNU Screen, Helix, Vim and Neovim in a terminal, btop++. They get glass from the terminal port when they leave the default background unset. btop has `theme_background = false` for this: "set to False if you want terminal background transparency." [btop README](https://github.com/aristocratos/btop/blob/main/README.md). Helix: "Helix doesn't support transparency (alpha channel)." [Helix themes](https://github.com/helix-editor/helix/blob/master/book/src/themes.md)
- **No window transparency:** VS Code (declined upstream, [vscode issue 32257](https://github.com/microsoft/vscode/issues/32257)) and Typora (the port's MAPPING.md says themes cannot make the window see-through).
- **Material Icon Theme:** its `opacity` setting fades icons. It is not a surface.
- **Notepad++:** only the Find dialog has a transparency setting ("On losing focus" or "Always", with a slider), and a theme does not control it. [Notepad++ manual: Searching](https://npp-user-manual.org/docs/searching)
- **GRUB:** draws before any desktop exists, so there is nothing behind it to show.
- **Not checked in depth:** Visual Studio, SumatraPDF, Dopamine, Ghidra, Halloy, Heroic Games Launcher, Insomnia, KiCad, Mod Organizer 2, OBS Studio, qBittorrent, Slack, Telegram Desktop. A short search found no window opacity setting for any of them. See [Not verified](#not-verified).

## What this means for the map

- Any rule for opacity-only glass applies to two Tier 1 ports today, Windows Terminal and GNOME Terminal, and to the translucent surfaces in Cinnamon and the preview's fallback.
- Only Windows Terminal can set panel and chrome alphas separately. GNOME Terminal has only a panel. Cinnamon and a future GTK port set any alpha per element.
- Windows Terminal's chrome alpha always sits over Mica, which is already blurred and wallpaper-tinted. Its panel alpha may sit over the raw wallpaper (Windows 11, acrylic off).
- Windows Terminal's one `opacity` per profile means one panel alpha for both variants, unless the user keeps one profile per variant.
- GNOME Terminal's default "use theme transparency" is on, so a user who skips the install script gets the GTK theme's value, not Hyaline's.

## Not verified

- **Linux Mint's GNOME Terminal.** The port README says Mint carries the transparency option. Mint's package source was not read here.
- **Whether GNOME Terminal's transparency needs a compositing window manager.** The patch does not say.
- **`TerminalScreen-background-darkness`.** Which GTK themes set it, and its value, was not checked.
- **GTK window translucency.** Whether an alpha window background reaches the desktop under Mutter, Marco (MATE), or Muffin, and whether GTK 4 `filter` supports `blur()`, was not checked.
- **Obsidian.** The default of "Translucent window", and whether a theme's background alpha controls how much shows through.
- **StartAllBack.** No settings docs exist. Its controls were not seen.
- **Windows Terminal acrylic tint and radius.** The docs do not say how `background` and `opacity` map onto the acrylic layers.
- **The "not checked in depth" apps** above. A code search on GitHub for Halloy, Heroic, and Dopamine found no window transparency setting, but a missing result is not proof, and the search hit a rate limit before Jellyfin's web client.
- **Nothing here was tested on a real machine.** This is a reading of docs and source files only.
