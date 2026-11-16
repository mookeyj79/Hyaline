# GNOME Terminal: role mapping

For maintainers. The install guide is [README.md](README.md).

## Role mapping

| Profile key | Preferences name | Role |
|---|---|---|
| `background-color` | Background | Flat: `panel_flat`. Glass: `panel` |
| `use-transparent-background` | Use transparent background | Flat: off. Glass: on |
| `background-transparency-percent` | the transparency slider | Glass: 100 minus `panel` opacity in percent (Dark 18, Light 4). The script computes it at install time |
| `use-theme-transparency` | Use transparency from system theme | off, so the palette sets the amount |
| `foreground-color` | Text | `text` |
| `bold-color-same-as-fg` | Bold color same as text | on, so bold uses `text` |
| `cursor-background-color` | Cursor background | `accent` |
| `cursor-foreground-color` | Cursor foreground | `on_accent` |
| `highlight-background-color` | Highlight background | `accent` |
| `highlight-foreground-color` | Highlight foreground | `on_accent` |
| `palette` 0, black | Palette | Dark `raised_flat`, Light `text` |
| `palette` 1 to 6 | Palette | `red`, `green`, `yellow`, `blue`, `magenta`, `cyan` |
| `palette` 7, white | Palette | Dark `text_dim`, Light `line` |
| `palette` 8, bright black | Palette | `text_muted` |
| `palette` 9 to 14 | Palette | same roles as 1 to 6 |
| `palette` 15, bright white | Palette | Dark `text`, Light `raised_flat` |
| `bold-is-bright` | Show bold text in bright colors | off, since bright colors reuse the normal roles |
| `use-theme-colors` | Use colors from system theme | off |
| `font`, `use-system-font` | Custom font | FiraCode Nerd Font Mono 12 |

Each variant has a fixed profile UUID, kept in `values.json`, so running the script again updates the profile instead of adding a copy.

## Gaps and trade-offs

- **Glass is partial.** Transparency only exists in builds that patch it back in, such as Ubuntu and Linux Mint, and the blur comes from the desktop, not the terminal. Upstream GNOME and Debian 13 builds get flat only. Tier 1 where glass works, Tier 2 elsewhere.
- **Glass without blur still reads.** The glass background is the `panel` tint at its dense alpha, which passes the contrast floor over pure black and pure white, so text reads over any wallpaper even when the desktop does not blur. A busy wallpaper stays sharp, though, so the README points those users to flat.
- **Window frame and tab bar** are drawn by the GTK theme, not the profile. They follow the Cinnamon or GNOME theme in use, and the **Theme variant** setting picks its light or dark version.
- **No automatic light and dark switching.** A profile has one set of colors, so switching variants means switching profiles.
- **Default profile on a brand new account.** If GNOME Terminal has never been opened, its profile list is still empty, and installing first leaves Hyaline as the only listed profile.
- **Not tested in a running GNOME Terminal yet.** The scripts were run with `dconf` and `gsettings` against GNOME Terminal's settings schema, both upstream and Ubuntu's 3.52 build with transparency.

## Research

- [GNOME Terminal settings schema](https://gitlab.gnome.org/GNOME/gnome-terminal/-/blob/master/src/org.gnome.Terminal.gschema.xml): every profile key, its type, and the profiles list path.
- [GNOME Terminal help: Manage profiles](https://help.gnome.org/users/gnome-terminal/stable/pref-profiles.html): Preferences, **Set as default**, **Delete...**, and **Terminal** > **Change Profile**.
- [GNOME Terminal help: Change font and style](https://help.gnome.org/users/gnome-terminal/stable/app-fonts.html): the **Custom font** steps.
- `debian/patches/0001-Restore-transparency.patch` in [Ubuntu's `gnome-terminal` 3.52.0-1ubuntu2 source package](http://archive.ubuntu.com/ubuntu/pool/main/g/gnome-terminal/gnome-terminal_3.52.0-1ubuntu2.debian.tar.xz): the transparency keys and how the percent turns into opacity.
- [Blur Cinnamon](https://cinnamon-spices.linuxmint.com/extensions/view/104): blur behind application windows on Cinnamon.
- [Catppuccin for GNOME Terminal](https://github.com/catppuccin/gnome-terminal) (MIT): studied for the method of one fixed profile UUID per variant, added to `org.gnome.Terminal.ProfilesList`. No files or code were reused.
