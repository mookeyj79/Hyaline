# Hyaline for GNOME Terminal

**Tier:** 1 Full glass (glass needs Ubuntu or Linux Mint and a blurring desktop; Flat everywhere else)
**Variants:** Hyaline Dark, Hyaline Light
**Tested with:** not yet tested in a running GNOME Terminal. The scripts were run with `dconf` and `gsettings` against GNOME Terminal's settings schema, both upstream and Ubuntu's 3.52 build with transparency (see Sources).

| Hyaline Dark | Hyaline Light |
|---|---|
| ![Hyaline Dark](screenshots/dark.png) | ![Hyaline Light](screenshots/light.png) |

<!-- Screenshots are added by hand. Leave the paths in place. -->

GNOME Terminal is the default terminal in Linux Mint Cinnamon, Ubuntu, Fedora Workstation, and other GNOME-based systems. It keeps its colors in **profiles**, which live in your settings database (dconf), not in a file. Each variant here is a small script that adds one profile: `Hyaline Dark` or `Hyaline Light`. Your existing profiles are not touched.

Each profile comes in two looks. The script installs one of them:

| Look | Use it when |
|---|---|
| Flat (default) | Any GNOME Terminal. A solid background. |
| Glass (`--glass`) | Ubuntu or Linux Mint, whose GNOME Terminal has a **Use transparent background** option. Add a blur on the desktop side to get real glass (see [Turn on the glass effect](#turn-on-the-glass-effect)). |

## Before you start

- GNOME Terminal 3.8 or later. Any version from the last decade works. Check it in **Help** > **About**.
- `dconf` and `gsettings` on the command line. Every GNOME and Cinnamon desktop has them. If `dconf` is missing, install `dconf-cli` (Debian, Ubuntu, Mint) or `dconf` (Fedora).

## Install

1. Download or clone this repo.
2. Open GNOME Terminal and `cd` into the repo folder.
3. Add both profiles and make Hyaline Dark the default:

   ```sh
   bash Ports/gnome-terminal/dist/light/install.sh
   bash Ports/gnome-terminal/dist/dark/install.sh --default
   ```

   Each script prints a line such as `Hyaline Dark (flat) is installed and is now the default profile.` Use `--default` on the variant you want new windows to open with. For glass, add `--glass` to each line and follow [Turn on the glass effect](#turn-on-the-glass-effect).
4. Close the window and open a new one. It opens with the default profile.

To install only one variant, run only its script. Running a script again updates the profile; it never adds a second copy. To switch between flat and glass, run the script again with or without `--glass`.

Files to use:

- Hyaline Dark: `dist/dark/install.sh`, `dist/dark/uninstall.sh`
- Hyaline Light: `dist/light/install.sh`, `dist/light/uninstall.sh`

## Set the font

Hyaline uses [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads). If it is not installed yet, follow [Font](../../README.md#font) in the main README.

The install script already sets **FiraCode Nerd Font Mono** at size 12 in both profiles. To change the size, or if the font was not installed when you ran the script:

1. Open **Edit** > **Preferences**. On builds without a menu bar, click the menu button in the top-right corner and pick **Preferences**.
2. In the sidebar, under **Profiles**, select **Hyaline Dark** or **Hyaline Light**.
3. Open the **Text** tab.
4. Tick **Custom font** and click the button next to it.
5. Search for `FiraCode Nerd Font Mono`, pick it, set the size, and click **Select**.

## Check that it worked

The terminal background is a soft slate in Dark and a pale frost in Light. Run `ls --color` in a folder with some files: folders show in blue, and the cursor is a solid blue block.

## Switch between Dark and Light

To change the profile of the window you are in:

1. Open **Terminal** > **Change Profile**.
2. Pick **Hyaline Dark** or **Hyaline Light**.

To change the default for new windows:

1. Open **Edit** > **Preferences**.
2. In the sidebar, select **Hyaline Dark** or **Hyaline Light**.
3. Click the arrow next to the profile name and pick **Set as default**.

Or from the command line, run the variant's script again with `--default`.

GNOME Terminal cannot switch profiles when the system switches between light and dark. The window frame and tab bar follow your GTK theme. To match them to the variant, open **Edit** > **Preferences** > **General** and set **Theme variant** to **Dark** or **Light**.

## Turn on the glass effect

GNOME Terminal can make its background see-through but cannot blur. The blur comes from the desktop. These steps are for Linux Mint Cinnamon 21.3 or later (Cinnamon 6.0 or later).

1. Install both profiles with `--glass`:

   ```sh
   bash Ports/gnome-terminal/dist/light/install.sh --glass
   bash Ports/gnome-terminal/dist/dark/install.sh --glass --default
   ```

2. Open a new window. The wallpaper now shows faintly through the background. This is the profile's **Colors** tab with **Use transparent background** ticked.
3. Open **System Settings** > **Extensions**, go to the **Download** tab, and install **Blur Cinnamon**.
4. On the **Manage** tab, select **Blur Cinnamon** and click **+** to turn it on.
5. Open its settings. On the **General setup** tab, turn on blurring for **Application windows**.
6. Under **Component specific settings**, open the **Windows** table and click **Pick a window to blur...**, then click a GNOME Terminal window.
7. Make sure the new row for GNOME Terminal is **Enabled**.

The wallpaper behind the terminal is now blurred. If the blur makes the desktop slow, switch the extension from Gaussian to **Dual Kawase** blur, which is lighter on the GPU.

On other desktops, the transparency works the same, but the blur needs that desktop's compositor or an extension that blurs behind windows. Without a blur, text still passes Hyaline's contrast floor, since the tint is the same as the panel's, but a busy wallpaper stays sharp behind it. Use flat in that case.

## Uninstall

1. Open GNOME Terminal and `cd` into the repo folder.
2. Run the uninstall script for each variant you installed:

   ```sh
   bash Ports/gnome-terminal/dist/dark/uninstall.sh
   bash Ports/gnome-terminal/dist/light/uninstall.sh
   ```

   If the profile was the default, the script makes your first other profile the default before removing it.
3. Close the window and open a new one.

You can also remove a profile by hand: **Edit** > **Preferences**, select it, click the arrow next to its name, and pick **Delete...**.

## Troubleshooting

- **`dconf: command not found`**: install the `dconf-cli` package (Debian, Ubuntu, Mint) or `dconf` (Fedora), then run the script again.
- **`No such schema "org.gnome.Terminal.ProfilesList"`**: GNOME Terminal is not installed, or you are running the script over SSH or in a different user session. Run it inside GNOME Terminal on the desktop.
- **The colors look right but the text is still the old font**: FiraCode Nerd Font is not installed. Install it, then reopen the window. See [Set the font](#set-the-font).
- **The uninstall script says it is your only profile**: GNOME Terminal needs at least one profile. Create another one in **Edit** > **Preferences** (the **+** next to **Profiles**), then run the script again.
- **The background shows the wallpaper through it, but you installed flat**: run the script again without `--glass`. It turns off **Use transparent background**.
- **`--glass` made no difference**: your GNOME Terminal build has no transparency option. Upstream GNOME and Debian builds do not have it; Ubuntu and Linux Mint add it back. Use flat.
- **The background is see-through but not blurred**: the desktop is not blurring it. See [Turn on the glass effect](#turn-on-the-glass-effect).

---

## Reference

### Role mapping

| Profile key | Preferences name | Role |
|---|---|---|
| `background-color` | Background | Flat: `panel_flat`. Glass: `panel` |
| `use-transparent-background` | Use transparent background | Flat: off. Glass: on |
| `background-transparency-percent` | the transparency slider | Glass: 100 minus `panel` opacity (Dark 20, Light 7) |
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

### Known gaps

- **Glass is partial.** Transparency only exists in builds that patch it back in such as Ubuntu and Linux Mint, and the blur comes from the desktop, not the terminal. Upstream GNOME and Debian 13 builds get flat only.
- **Window frame and tab bar** are drawn by the GTK theme, not the profile. They follow the Cinnamon or GNOME theme you use, and the **Theme variant** setting picks its light or dark version.
- **No automatic light and dark switching.** A profile has one set of colors, so switching variants means switching profiles.
- **Default profile on a brand new account.** If GNOME Terminal has never been opened, its profile list is still empty, and installing first leaves Hyaline as the only listed profile. Open GNOME Terminal once before installing to avoid this.

### Sources and credits

- [GNOME Terminal settings schema](https://gitlab.gnome.org/GNOME/gnome-terminal/-/blob/master/src/org.gnome.Terminal.gschema.xml): every profile key, its type, and the profiles list path.
- [GNOME Terminal help: Manage profiles](https://help.gnome.org/users/gnome-terminal/stable/pref-profiles.html): Preferences, **Set as default**, **Delete...**, and **Terminal** > **Change Profile**.
- [GNOME Terminal help: Change font and style](https://help.gnome.org/users/gnome-terminal/stable/app-fonts.html): the **Custom font** steps.
- `debian/patches/0001-Restore-transparency.patch` in [Ubuntu's `gnome-terminal` 3.52.0-1ubuntu2 source package](http://archive.ubuntu.com/ubuntu/pool/main/g/gnome-terminal/gnome-terminal_3.52.0-1ubuntu2.debian.tar.xz): the transparency keys and how the percent turns into opacity.
- [Blur Cinnamon](https://cinnamon-spices.linuxmint.com/extensions/view/104): blur behind application windows on Cinnamon.
- [Catppuccin for GNOME Terminal](https://github.com/catppuccin/gnome-terminal) (MIT): studied for the method of one fixed profile UUID per variant, added to `org.gnome.Terminal.ProfilesList`. No files or code were reused.
